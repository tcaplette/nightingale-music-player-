import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:nightingale/core/activitypub/models/ap_activity.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/delivery/activity_delivery_service.dart';
import 'package:nightingale/features/federation/nat/peer_address_activity.dart';
import 'package:nightingale/features/federation/stun/stun_address_resolver.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

const _tag = 'hole_punch';
const _udpIntervalMs = 200;
const _holePunchTimeout = Duration(seconds: 8);

class HolePunchService {
  HolePunchService({
    required ActorResolver actorResolver,
    required ActivityDeliveryService delivery,
    required NodeIdentityRepository identityRepo,
    required StunAddressResolver stunResolver,
  })  : _actorResolver = actorResolver,
        _delivery = delivery,
        _identityRepo = identityRepo,
        _stunResolver = stunResolver;

  final ActorResolver _actorResolver;
  final ActivityDeliveryService _delivery;
  final NodeIdentityRepository _identityRepo;
  final StunAddressResolver _stunResolver;

  // nonce → completer that resolves with the peer's public address once their
  // PeerAddress activity arrives.
  final _pendingByNonce = <String, Completer<PeerAddressActivity?>>{};

  /// Attempts UDP hole punching to [actorUrl].
  ///
  /// Returns the peer's reachable `host:port` if punching succeeds within
  /// 8 seconds, null on timeout (symmetric NAT or Mastodon delivery too slow).
  Future<String?> attemptHolePunch(String actorUrl) async {
    final result = await _actorResolver.resolve(actorUrl);
    if (result is! ResolveOk) {
      AppLogger.warning(
        'HolePunch: cannot resolve actor $actorUrl',
        tag: _tag,
      );
      return null;
    }
    final peerActor = result.actor;
    if (peerActor.inbox.isEmpty) {
      AppLogger.warning(
        'HolePunch: peer actor $actorUrl has no inbox URL — cannot signal',
        tag: _tag,
      );
      return null;
    }

    // Bind the UDP socket first so we know our local port before sending the
    // PeerAddress activity.
    final RawDatagramSocket socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (e) {
      AppLogger.error(
        'HolePunch: failed to bind UDP socket: $e',
        tag: _tag,
        error: e,
      );
      return null;
    }
    final localPort = socket.port;

    // Discover our public address via STUN so we can include it in the signal.
    final publicAddr = await _stunResolver.resolve();
    if (publicAddr == null) {
      AppLogger.warning(
        'HolePunch: STUN resolve returned null — will advertise local port $localPort '
        'with 0.0.0.0 IP; hole punch will likely fail',
        tag: _tag,
      );
    }
    final localActorUrl = await _identityRepo.getActorUrl();

    final nonce = _generateNonce();
    final localIp = publicAddr?.split(':').first ?? '0.0.0.0';
    final publicAddress = publicAddr ?? '$localIp:$localPort';
    final localAddress = '$localIp:$localPort';

    AppLogger.info(
      'HolePunch: starting session nonce=$nonce '
      'localAddress=$localAddress publicAddress=$publicAddress → $actorUrl',
      tag: _tag,
    );

    final completer = Completer<PeerAddressActivity?>();
    _pendingByNonce[nonce] = completer;

    final peerAddress = PeerAddressActivity(
      id: '${localActorUrl}/peer-address/${DateTime.now().millisecondsSinceEpoch}',
      fromActorUrl: localActorUrl,
      toActorUrl: actorUrl,
      sessionNonce: nonce,
      publicAddress: publicAddress,
      localAddress: localAddress,
      timestamp: DateTime.now().toUtc(),
    );

    // Deliver to peer's inbox (works when peer has a public Nightingale address;
    // gracefully times out if peer is fully NATted).
    await _delivery.deliver(peerAddress.toApActivity(), peerActor.inbox);
    AppLogger.info(
      'HolePunch: sent PeerAddress to ${peerActor.inbox} nonce=$nonce',
      tag: _tag,
    );

    try {
      final peerAddrActivity = await completer.future.timeout(_holePunchTimeout);
      if (peerAddrActivity == null) {
        socket.close();
        return null;
      }

      final parts = peerAddrActivity.publicAddress.split(':');
      if (parts.length != 2) {
        AppLogger.warning(
          'HolePunch: peer returned malformed publicAddress '
          '"${peerAddrActivity.publicAddress}" nonce=$nonce',
          tag: _tag,
        );
        socket.close();
        return null;
      }
      final peerHost = parts[0];
      final peerPort = int.tryParse(parts[1]);
      if (peerPort == null) {
        AppLogger.warning(
          'HolePunch: peer publicAddress port is not a number '
          '"${peerAddrActivity.publicAddress}" nonce=$nonce',
          tag: _tag,
        );
        socket.close();
        return null;
      }

      AppLogger.info(
        'HolePunch: received peer address $peerHost:$peerPort — starting UDP fire',
        tag: _tag,
      );

      // Fire UDP packets at the peer's public address at 200ms intervals.
      // Each packet contains the session nonce so the peer can validate.
      final nonceBytes = Uint8List.fromList(nonce.codeUnits);
      final peerInternetAddr = InternetAddress(peerHost);

      final successCompleter = Completer<bool>();

      // Send loop.
      final timer = Timer.periodic(
        const Duration(milliseconds: _udpIntervalMs),
        (_) => socket.send(nonceBytes, peerInternetAddr, peerPort),
      );

      // Listen for a valid UDP response containing the nonce.
      final sub = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket.receive();
        if (datagram == null) return;
        final received = String.fromCharCodes(datagram.data);
        if (received == nonce && !successCompleter.isCompleted) {
          successCompleter.complete(true);
        }
      });

      bool punched = false;
      try {
        punched = await successCompleter.future.timeout(_holePunchTimeout);
      } on TimeoutException {
        AppLogger.warning(
          'HolePunch: timed out waiting for UDP echo from $peerHost:$peerPort',
          tag: _tag,
        );
      } finally {
        timer.cancel();
        await sub.cancel();
        socket.close();
      }

      if (punched) {
        AppLogger.info(
          'HolePunch: SUCCESS — punched through to $peerHost:$peerPort nonce=$nonce',
          tag: _tag,
        );
      }
      return punched ? peerAddrActivity.publicAddress : null;
    } on TimeoutException {
      AppLogger.warning(
        'HolePunch: timed out waiting for PeerAddress from $actorUrl',
        tag: _tag,
      );
      _pendingByNonce.remove(nonce);
      socket.close();
      return null;
    }
  }

  /// Called by the inbox handler when a [ApPeerAddress] activity arrives.
  ///
  /// If the nonce matches a waiting session, the completer is resolved and
  /// we echo our own address back to the peer so they can start their fire loop.
  void handleIncomingPeerAddress(ApPeerAddress apActivity) {
    final parsed = PeerAddressActivity.fromApActivity(apActivity);
    if (parsed == null) {
      AppLogger.warning(
        'HolePunch: received malformed PeerAddress from ${apActivity.actor} '
        '— missing required fields in object',
        tag: _tag,
      );
      return;
    }

    AppLogger.info(
      'HolePunch: incoming PeerAddress nonce=${parsed.sessionNonce} from ${parsed.fromActorUrl}',
      tag: _tag,
    );

    final completer = _pendingByNonce.remove(parsed.sessionNonce);
    if (completer != null && !completer.isCompleted) {
      AppLogger.info(
        'HolePunch: resolved waiting session nonce=${parsed.sessionNonce}',
        tag: _tag,
      );
      completer.complete(parsed);
    } else {
      AppLogger.debug(
        'HolePunch: no waiting session for nonce=${parsed.sessionNonce} '
        '(this node is acting as the server side — will echo back)',
        tag: _tag,
      );
    }

    // Echo our own PeerAddress back so the peer can complete their session.
    _echoBack(parsed).ignore();
  }

  Future<void> _echoBack(PeerAddressActivity incoming) async {
    final result = await _actorResolver.resolve(incoming.fromActorUrl);
    if (result is! ResolveOk) {
      AppLogger.warning(
        'HolePunch: echo-back failed — cannot resolve ${incoming.fromActorUrl}',
        tag: _tag,
      );
      return;
    }
    final peerActor = result.actor;

    final publicAddr = await _stunResolver.resolve();
    if (publicAddr == null) {
      AppLogger.warning(
        'HolePunch: echo-back STUN resolve failed — will send 0.0.0.0:0; '
        'peer hole punch will likely fail nonce=${incoming.sessionNonce}',
        tag: _tag,
      );
    }
    final localActorUrl = await _identityRepo.getActorUrl();

    final echo = PeerAddressActivity(
      id: '$localActorUrl/peer-address-echo/${DateTime.now().millisecondsSinceEpoch}',
      fromActorUrl: localActorUrl,
      toActorUrl: incoming.fromActorUrl,
      sessionNonce: incoming.sessionNonce,
      publicAddress: publicAddr ?? '0.0.0.0:0',
      localAddress: publicAddr ?? '0.0.0.0:0',
      timestamp: DateTime.now().toUtc(),
    );

    AppLogger.info(
      'HolePunch: sending echo PeerAddress nonce=${incoming.sessionNonce} '
      'publicAddress=${echo.publicAddress} → ${incoming.fromActorUrl}',
      tag: _tag,
    );
    await _delivery.deliver(echo.toApActivity(), peerActor.inbox);

    // Also start firing UDP packets at the peer so our NAT creates a mapping.
    final parts = incoming.publicAddress.split(':');
    if (parts.length != 2) {
      AppLogger.warning(
        'HolePunch: echo-back — peer publicAddress malformed '
        '"${incoming.publicAddress}" nonce=${incoming.sessionNonce}',
        tag: _tag,
      );
      return;
    }
    final peerHost = parts[0];
    final peerPort = int.tryParse(parts[1]);
    if (peerPort == null) {
      AppLogger.warning(
        'HolePunch: echo-back — peer publicAddress port not a number '
        '"${incoming.publicAddress}" nonce=${incoming.sessionNonce}',
        tag: _tag,
      );
      return;
    }

    final RawDatagramSocket echoSocket;
    try {
      echoSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (e) {
      AppLogger.error(
        'HolePunch: echo-back failed to bind UDP socket: $e',
        tag: _tag,
        error: e,
      );
      return;
    }

    AppLogger.info(
      'HolePunch: echo-back firing UDP at $peerHost:$peerPort '
      'nonce=${incoming.sessionNonce}',
      tag: _tag,
    );

    final nonceBytes = Uint8List.fromList(incoming.sessionNonce.codeUnits);
    final peerAddr = InternetAddress(peerHost);
    var closed = false;

    void closeOnce() {
      if (!closed) {
        closed = true;
        echoSocket.close();
      }
    }

    // Fire for 8 seconds to keep the NAT mapping open.
    var ticks = 0;
    final timer = Timer.periodic(const Duration(milliseconds: _udpIntervalMs), (_) {
      if (closed) return;
      echoSocket.send(nonceBytes, peerAddr, peerPort);
      ticks++;
      if (ticks * _udpIntervalMs >= _holePunchTimeout.inMilliseconds) {
        closeOnce();
      }
    });

    // Echo any nonce packets back (so A's listener resolves).
    echoSocket.listen(
      (event) {
        if (event != RawSocketEvent.read) return;
        final datagram = echoSocket.receive();
        if (datagram == null) return;
        final received = String.fromCharCodes(datagram.data);
        if (received == incoming.sessionNonce && !closed) {
          echoSocket.send(nonceBytes, datagram.address, datagram.port);
        }
      },
      onError: (Object e) {
        AppLogger.debug(
          'HolePunch: echo-back UDP socket error: $e nonce=${incoming.sessionNonce}',
          tag: _tag,
        );
      },
    );

    await Future.delayed(_holePunchTimeout);
    timer.cancel();
    closeOnce();
  }

  String _generateNonce() {
    final rng = Random.secure();
    final bytes = Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
