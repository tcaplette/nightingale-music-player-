import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:nightingale/core/activitypub/models/ap_activity.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/delivery/activity_delivery_service.dart';
import 'package:nightingale/features/federation/discovery/mastodon_signaling_service.dart';
import 'package:nightingale/features/federation/nat/peer_address_activity.dart';
import 'package:nightingale/features/federation/stun/stun_address_resolver.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';
import 'package:nightingale/features/onboarding/secure_storage_service.dart';

const _tag = 'hole_punch';
const _udpIntervalMs = 200;
const _holePunchTimeout = Duration(seconds: 8);
const _mastodonSignalTimeout = Duration(seconds: 20);

class HolePunchService {
  HolePunchService({
    required ActorResolver actorResolver,
    required ActivityDeliveryService delivery,
    required NodeIdentityRepository identityRepo,
    required StunAddressResolver stunResolver,
    required AppDatabase db,
    required SecureStorageService storage,
    MastodonSignalingService? signaling,
  })  : _actorResolver = actorResolver,
        _delivery = delivery,
        _identityRepo = identityRepo,
        _stunResolver = stunResolver,
        _db = db,
        _storage = storage,
        _signaling = signaling;

  final ActorResolver _actorResolver;
  final ActivityDeliveryService _delivery;
  final NodeIdentityRepository _identityRepo;
  final StunAddressResolver _stunResolver;
  final AppDatabase _db;
  final SecureStorageService _storage;
  final MastodonSignalingService? _signaling;

  // nonce → completer that resolves with the peer's public address once their
  // PeerAddress activity arrives.
  final _pendingByNonce = <String, Completer<PeerAddressActivity?>>{};

  /// Attempts UDP hole punching to [actorUrl].
  ///
  /// Returns the peer's reachable `host:port` if punching succeeds within
  /// the timeout, null on failure. Uses the Mastodon DM fallback path when
  /// both own and peer Mastodon handles are known.
  Future<String?> attemptHolePunch(String actorUrl) async {
    print('DEBUG_HOLEPUNCH: attemptHolePunch called for $actorUrl');
    final result = await _actorResolver.resolve(actorUrl);
    print('DEBUG_HOLEPUNCH: actor resolve result=${result.runtimeType}');
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

    // Resolve Mastodon handles for the DM fallback path.
    String? ownMastodonHandle;
    String? peerMastodonHandle;
    if (_signaling != null) {
      ownMastodonHandle = await _storage.getMastodonHandle();
      peerMastodonHandle = await _peerMastodonHandle(actorUrl);
    }
    print('DEBUG_HOLEPUNCH: ownHandle=$ownMastodonHandle peerHandle=$peerMastodonHandle signalingAvailable=${_signaling != null}');

    final nonce = _generateNonce();
    final localIp = publicAddr?.split(':').first ?? '0.0.0.0';
    final publicAddress = publicAddr ?? '$localIp:$localPort';
    final localAddress = '$localIp:$localPort';

    AppLogger.info(
      'HolePunch: starting session nonce=$nonce '
      'localAddress=$localAddress publicAddress=$publicAddress → $actorUrl '
      'mastodonFallback=${peerMastodonHandle != null}',
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
      senderMastodonHandle: ownMastodonHandle,
    );

    // Deliver to peer's Nightingale inbox (works when peer has a public address;
    // gracefully fails silently if peer is fully NATted).
    await _delivery.deliver(peerAddress.toApActivity(), peerActor.inbox);
    AppLogger.info(
      'HolePunch: sent PeerAddress to ${peerActor.inbox} nonce=$nonce',
      tag: _tag,
    );

    // Mastodon DM fallback — fire in parallel when handles are available.
    Timer? pollTimer;
    if (_signaling != null &&
        ownMastodonHandle != null &&
        peerMastodonHandle != null) {
      AppLogger.info(
        'HolePunch: sending PeerAddress via Mastodon DM to $peerMastodonHandle '
        'nonce=$nonce',
        tag: _tag,
      );
      _signaling!
          .sendSignal(
            targetMastodonHandle: peerMastodonHandle,
            signal: peerAddress,
          )
          .ignore();

      // Poll for echo at 1s intervals while waiting.
      var pollBusy = false;
      pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (pollBusy) return;
        pollBusy = true;
        try {
          final signals = await _signaling!.pollOnce();
          for (final signal in signals) {
            AppLogger.info(
              'HolePunch: received PeerAddress via Mastodon poll '
              'nonce=${signal.sessionNonce}',
              tag: _tag,
            );
            _handleParsedPeerAddress(signal);
          }
        } finally {
          pollBusy = false;
        }
      });
    }

    final timeout =
        pollTimer != null ? _mastodonSignalTimeout : _holePunchTimeout;

    try {
      final peerAddrActivity = await completer.future.timeout(timeout);
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
      final nonceBytes = Uint8List.fromList(nonce.codeUnits);
      final peerInternetAddr = InternetAddress(peerHost);

      final successCompleter = Completer<bool>();

      final timer = Timer.periodic(
        const Duration(milliseconds: _udpIntervalMs),
        (_) => socket.send(nonceBytes, peerInternetAddr, peerPort),
      );

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
    } finally {
      pollTimer?.cancel();
    }
  }

  /// Called by the inbox handler when a [ApPeerAddress] activity arrives.
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
    _handleParsedPeerAddress(parsed);
  }

  /// Called by [MastodonSignalingService] background polling when a signal
  /// arrives via Mastodon DM rather than the Nightingale inbox.
  void handleIncomingPeerAddressFromMastodon(PeerAddressActivity signal) {
    AppLogger.info(
      'HolePunch: incoming PeerAddress via Mastodon poll '
      'nonce=${signal.sessionNonce} from ${signal.fromActorUrl}',
      tag: _tag,
    );
    _handleParsedPeerAddress(signal);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  void _handleParsedPeerAddress(PeerAddressActivity parsed) {
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
      _echoBack(parsed).ignore();
    }
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
    final ownMastodonHandle = _signaling != null
        ? await _storage.getMastodonHandle()
        : null;

    final echo = PeerAddressActivity(
      id: '$localActorUrl/peer-address-echo/${DateTime.now().millisecondsSinceEpoch}',
      fromActorUrl: localActorUrl,
      toActorUrl: incoming.fromActorUrl,
      sessionNonce: incoming.sessionNonce,
      publicAddress: publicAddr ?? '0.0.0.0:0',
      localAddress: publicAddr ?? '0.0.0.0:0',
      timestamp: DateTime.now().toUtc(),
      senderMastodonHandle: ownMastodonHandle,
    );

    AppLogger.info(
      'HolePunch: sending echo PeerAddress nonce=${incoming.sessionNonce} '
      'publicAddress=${echo.publicAddress} → ${incoming.fromActorUrl}',
      tag: _tag,
    );
    await _delivery.deliver(echo.toApActivity(), peerActor.inbox);

    // Mastodon DM echo-back when the incoming signal carried the sender's handle.
    if (_signaling != null && incoming.senderMastodonHandle != null) {
      AppLogger.info(
        'HolePunch: sending echo via Mastodon DM to ${incoming.senderMastodonHandle} '
        'nonce=${incoming.sessionNonce}',
        tag: _tag,
      );
      _signaling!
          .sendSignal(
            targetMastodonHandle: incoming.senderMastodonHandle!,
            signal: echo,
          )
          .ignore();
    }

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

    var ticks = 0;
    final timer = Timer.periodic(const Duration(milliseconds: _udpIntervalMs), (_) {
      if (closed) return;
      echoSocket.send(nonceBytes, peerAddr, peerPort);
      ticks++;
      if (ticks * _udpIntervalMs >= _holePunchTimeout.inMilliseconds) {
        closeOnce();
      }
    });

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

  Future<String?> _peerMastodonHandle(String actorUrl) async {
    final row = await (_db.select(_db.followsTable)
          ..where((t) => t.remoteActorUrl.equals(actorUrl)))
        .getSingleOrNull();
    return row?.mastodonHandle;
  }

  String _generateNonce() {
    final rng = Random.secure();
    final bytes = Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
