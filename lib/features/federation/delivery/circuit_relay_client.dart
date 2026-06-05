import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:nightingale/core/activitypub/models/ap_activity.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/delivery/activity_delivery_service.dart';

const _tag = 'relay';
const _sessionTimeout = Duration(seconds: 30);

abstract class CircuitRelayClient {
  /// Discovers a reachable relay from the actor cache and establishes a session.
  ///
  /// Sends a [RelayRequest] to the relay's inbox, waits for both sides to
  /// connect, and returns a `http://127.0.0.1:<port>` base URL backed by a
  /// local TCP proxy that pipes through the relay to [remoteActorUrl].
  ///
  /// Returns null if no reachable relay is found or session establishment fails.
  Future<String?> openRelaySession({
    required String localActorUrl,
    required String remoteActorUrl,
  });

  /// Called when a [RelayRequest] activity arrives in the inbox. Connects
  /// outbound to the named relay as the server-side peer.
  Future<void> connectAsRelayServer({
    required String sessionId,
    required String relayAddress,
  });
}

class CircuitRelayClientImpl implements CircuitRelayClient {
  CircuitRelayClientImpl({
    required AppDatabase db,
    required ActorResolver actorResolver,
    required ActivityDeliveryService delivery,
  })  : _db = db,
        _actorResolver = actorResolver,
        _delivery = delivery;

  final AppDatabase _db;
  final ActorResolver _actorResolver;
  final ActivityDeliveryService _delivery;

  @override
  Future<String?> openRelaySession({
    required String localActorUrl,
    required String remoteActorUrl,
  }) async {
    final relayAddress = await _findReachableRelay();
    if (relayAddress == null) {
      AppLogger.warning('CircuitRelay: no reachable relay found', tag: _tag);
      return null;
    }

    final sessionId = _generateSessionId();
    AppLogger.info(
      'CircuitRelay: opening session=$sessionId via relay=$relayAddress',
      tag: _tag,
    );

    // Signal the remote peer via their inbox so they also connect to the relay.
    final remoteResult = await _actorResolver.resolve(remoteActorUrl);
    if (remoteResult is! ResolveOk) {
      AppLogger.warning(
        'CircuitRelay: cannot resolve remote actor $remoteActorUrl — '
        'cannot send RelayRequest session=$sessionId',
        tag: _tag,
      );
      return null;
    }

    final relayRequest = ApRelayRequest(
      id: '$localActorUrl/relay-request/$sessionId',
      actor: localActorUrl,
      object: {
        'type': 'RelayRequestObject',
        'sessionId': sessionId,
        'relayAddress': relayAddress,
        'requesterActorUrl': localActorUrl,
      },
      to: [remoteActorUrl],
    );
    await _delivery.deliver(relayRequest, remoteResult.actor.inbox);

    // Connect outbound to the relay as the requester side.
    final parts = relayAddress.split(':');
    if (parts.length != 2) {
      AppLogger.error(
        'CircuitRelay: relay address malformed "$relayAddress" session=$sessionId',
        tag: _tag,
      );
      return null;
    }
    final relayHost = parts[0];
    final relayPort = int.tryParse(parts[1]);
    if (relayPort == null) {
      AppLogger.error(
        'CircuitRelay: relay port not a number in "$relayAddress" session=$sessionId',
        tag: _tag,
      );
      return null;
    }

    try {
      final relaySocket = await Socket.connect(relayHost, relayPort + 1)
          .timeout(_sessionTimeout);

      // Relay handshake: identify role and session.
      relaySocket.write('REQUESTER $sessionId\n');
      await relaySocket.flush();

      // Read OK from relay.
      final response = await _readLine(relaySocket).timeout(_sessionTimeout);
      if (response != 'OK') {
        AppLogger.warning(
          'CircuitRelay: unexpected handshake response "$response" '
          'from relay=$relayAddress session=$sessionId (expected "OK")',
          tag: _tag,
        );
        relaySocket.destroy();
        return null;
      }

      // Start local proxy: localhost → relay socket (piped to remote peer).
      final localServer =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      _startLocalProxy(localServer, relaySocket);

      AppLogger.info(
        'CircuitRelay: local proxy on ${localServer.port} → relay $relayAddress session=$sessionId',
        tag: _tag,
      );

      return 'http://127.0.0.1:${localServer.port}';
    } catch (e) {
      AppLogger.warning('CircuitRelay: session setup failed: $e', tag: _tag);
      return null;
    }
  }

  @override
  Future<void> connectAsRelayServer({
    required String sessionId,
    required String relayAddress,
  }) async {
    final parts = relayAddress.split(':');
    if (parts.length != 2) return;
    final relayHost = parts[0];
    final relayPort = int.tryParse(parts[1]);
    if (relayPort == null) return;

    AppLogger.info(
      'CircuitRelay: connecting as server session=$sessionId to relay=$relayAddress',
      tag: _tag,
    );

    try {
      final relaySocket = await Socket.connect(relayHost, relayPort + 1)
          .timeout(_sessionTimeout);

      relaySocket.write('SERVER $sessionId\n');
      await relaySocket.flush();

      final response = await _readLine(relaySocket).timeout(_sessionTimeout);
      if (response != 'OK') {
        AppLogger.warning(
          'CircuitRelay: unexpected server handshake response "$response" '
          'from relay=$relayAddress session=$sessionId',
          tag: _tag,
        );
        relaySocket.destroy();
        return;
      }

      // Pipe relay ↔ local Nightingale server (127.0.0.1:port determined from
      // the relay port convention — same as FederationServer's preferred port).
      final localServer = await Socket.connect(
        InternetAddress.loopbackIPv4,
        relayPort,
      );

      relaySocket.listen(localServer.add, onDone: localServer.destroy);
      localServer.listen(relaySocket.add, onDone: relaySocket.destroy);

      AppLogger.info(
        'CircuitRelay: server side piped relay=$relayAddress ↔ localhost:$relayPort session=$sessionId',
        tag: _tag,
      );
    } catch (e) {
      AppLogger.warning(
        'CircuitRelay: server connect failed: $e',
        tag: _tag,
      );
    }
  }

  // ── Relay discovery ─────────────────────────────────────────────────────────

  Future<String?> _findReachableRelay() async {
    // Query actor cache for relay-capable actors.
    final rows = await _db.select(_db.actorCacheTable).get();
    final candidates = <String>[];

    for (final row in rows) {
      try {
        final json = jsonDecode(row.actorJson) as Map<String, dynamic>;
        final nightingaleRelay = json['x-nightingale-relay'] as bool? ?? false;
        if (!nightingaleRelay) continue;

        final address = json['x-nightingale-public-address'] as String?;
        if (address == null) {
          AppLogger.debug(
            'CircuitRelay: relay-capable actor ${json['id']} has no '
            'x-nightingale-public-address — skipping',
            tag: _tag,
          );
          continue;
        }
        candidates.add(address);
      } catch (e) {
        AppLogger.debug(
          'CircuitRelay: failed to parse actor cache row: $e',
          tag: _tag,
        );
      }
    }

    AppLogger.info(
      'CircuitRelay: found ${candidates.length} relay candidate(s) in actor cache',
      tag: _tag,
    );

    for (final address in candidates) {
      try {
        final uri = Uri.parse('http://$address/');
        final response =
            await http.head(uri).timeout(const Duration(seconds: 3));
        if (response.statusCode < 500) {
          AppLogger.info(
            'CircuitRelay: relay at $address is reachable '
            '(status ${response.statusCode})',
            tag: _tag,
          );
          return address;
        }
        AppLogger.debug(
          'CircuitRelay: relay at $address returned ${response.statusCode} — skipping',
          tag: _tag,
        );
      } catch (e) {
        AppLogger.debug(
          'CircuitRelay: probe failed for relay at $address: $e',
          tag: _tag,
        );
      }
    }

    AppLogger.warning(
      'CircuitRelay: no reachable relay found among ${candidates.length} candidate(s)',
      tag: _tag,
    );
    return null;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _startLocalProxy(ServerSocket localServer, Socket relaySocket) {
    localServer.listen((clientSocket) {
      clientSocket.listen(relaySocket.add, onDone: relaySocket.destroy);
      relaySocket.listen(clientSocket.add, onDone: clientSocket.destroy);
    });
  }

  Future<String> _readLine(Socket socket) async {
    final buffer = StringBuffer();
    await for (final chunk in socket) {
      for (final byte in chunk) {
        if (byte == 10 /* \n */) return buffer.toString().trim();
        buffer.writeCharCode(byte);
      }
    }
    return buffer.toString().trim();
  }

  String _generateSessionId() {
    final rng = Random.secure();
    final bytes =
        Uint8List.fromList(List.generate(16, (_) => rng.nextInt(256)));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
