import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/federation/nightingale_actor_validator.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/delivery/circuit_relay_client.dart';
import 'package:nightingale/features/federation/nat/hole_punch_service.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

const _tag = 'connection_negotiator';
const _cacheTtl = Duration(minutes: 5);
const _directProbeTimeout = Duration(seconds: 4);

class _CacheEntry {
  _CacheEntry(this.baseUrl) : expiresAt = DateTime.now().add(_cacheTtl);
  final String? baseUrl;
  final DateTime expiresAt;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Orchestrates the three-tier connection strategy for reaching a federated peer:
///   1. Direct HTTP probe (Tier 1 — peer has a public IP)
///   2. UDP hole punching (Tier 2 — both peers behind NAT)
///   3. Circuit relay (Tier 3 — symmetric NAT, relay required)
///
/// Results are cached per actor URL with a 5-minute TTL.
class ConnectionNegotiator {
  ConnectionNegotiator({
    required ActorResolver actorResolver,
    required HolePunchService holePunchService,
    required CircuitRelayClient relayClient,
    required NodeIdentityRepository identityRepo,
    required NightingaleActorValidator validator,
  })  : _actorResolver = actorResolver,
        _holePunch = holePunchService,
        _relay = relayClient,
        _identityRepo = identityRepo,
        _validator = validator;

  final ActorResolver _actorResolver;
  final HolePunchService _holePunch;
  final CircuitRelayClient _relay;
  final NodeIdentityRepository _identityRepo;
  final NightingaleActorValidator _validator;

  final _cache = <String, _CacheEntry>{};

  /// Returns a base URL (`http://host:port`) for reaching [actorUrl], or null
  /// if all tiers fail. Results are cached for 5 minutes.
  Future<String?> resolveEndpoint(String actorUrl) async {
    final cached = _cache[actorUrl];
    if (cached != null && !cached.isExpired) {
      AppLogger.debug(
        'ConnectionNegotiator: cache hit for $actorUrl → ${cached.baseUrl}',
        tag: _tag,
      );
      return cached.baseUrl;
    }

    AppLogger.info(
      'ConnectionNegotiator: negotiating connection to $actorUrl',
      tag: _tag,
    );
    final result = await _negotiate(actorUrl);
    _cache[actorUrl] = _CacheEntry(result);
    return result;
  }

  Future<String?> _negotiate(String actorUrl) async {
    // ── Tier 1: direct HTTP probe ─────────────────────────────────────────────
    print('DEBUG_NEGOTIATE: starting tier1 for $actorUrl');
    final directUrl = await _tryDirect(actorUrl);
    print('DEBUG_NEGOTIATE: tier1 result=$directUrl');
    if (directUrl != null) {
      AppLogger.info(
        'ConnectionNegotiator: direct path to $actorUrl → $directUrl',
        tag: _tag,
      );
      return directUrl;
    }

    // ── Tier 2: UDP hole punching ─────────────────────────────────────────────
    print('DEBUG_NEGOTIATE: starting tier2 holepunch for $actorUrl');
    final punchedAddress = await _holePunch.attemptHolePunch(actorUrl);
    print('DEBUG_NEGOTIATE: tier2 result=$punchedAddress');
    if (punchedAddress != null) {
      AppLogger.info(
        'ConnectionNegotiator: hole-punch path to $actorUrl → $punchedAddress',
        tag: _tag,
      );
      return 'http://$punchedAddress';
    }

    // ── Tier 3: circuit relay ─────────────────────────────────────────────────
    final localActorUrl = await _identityRepo.getActorUrl();
    final relayUrl = await _relay.openRelaySession(
      localActorUrl: localActorUrl,
      remoteActorUrl: actorUrl,
    );
    if (relayUrl != null) {
      AppLogger.info(
        'ConnectionNegotiator: relay path to $actorUrl → $relayUrl',
        tag: _tag,
      );
      return relayUrl;
    }

    AppLogger.warning(
      'ConnectionNegotiator: all tiers failed for $actorUrl',
      tag: _tag,
    );
    return null;
  }

  Future<String?> _tryDirect(String actorUrl) async {
    final result = await _actorResolver.resolve(actorUrl);
    if (result is! ResolveOk) {
      AppLogger.debug(
        'ConnectionNegotiator: actor resolve failed for $actorUrl ($result) '
        '— skipping direct probe',
        tag: _tag,
      );
      return null;
    }
    final actor = result.actor;

    if (!_validator.isNightingalePeer(actor)) {
      AppLogger.debug(
        'ConnectionNegotiator: $actorUrl is not a Nightingale peer — skipping direct probe',
        tag: _tag,
      );
      return null;
    }

    final String baseUrl;
    if (actor.nightingalePublicAddress != null) {
      baseUrl = 'http://${actor.nightingalePublicAddress}';
    } else {
      baseUrl = actor.id.replaceAll('/users/${actor.preferredUsername}', '');
    }

    final probeUri = Uri.parse('$baseUrl/users/${actor.preferredUsername}');
    AppLogger.debug(
      'ConnectionNegotiator: probing direct path → $probeUri',
      tag: _tag,
    );

    try {
      final response = await http.head(probeUri).timeout(_directProbeTimeout);
      if (response.statusCode < 500) return baseUrl;
      AppLogger.debug(
        'ConnectionNegotiator: direct probe returned ${response.statusCode} '
        'for $probeUri — not usable',
        tag: _tag,
      );
    } catch (e) {
      AppLogger.debug(
        'ConnectionNegotiator: direct probe failed for $probeUri: $e',
        tag: _tag,
      );
    }
    return null;
  }

  /// Evicts the cache entry for [actorUrl] so the next call re-negotiates.
  void invalidate(String actorUrl) => _cache.remove(actorUrl);
}
