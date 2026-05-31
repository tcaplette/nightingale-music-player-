import 'dart:async';
import 'dart:io';

import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/mdns/mdns_discovery_service.dart';

const _tag = 'reachability';

/// Checks if a remote node is reachable, consulting addresses in priority order:
/// 1. mDNS-resolved address (for local network peers)
/// 2. STUN-discovered address from the remote actor's x-nightingale-public-address
/// 3. The stored actor URL host
class NodeReachabilityService {
  NodeReachabilityService({
    this.timeout = const Duration(seconds: 5),
    MdnsDiscoveryService? mdns,
  }) : _mdns = mdns;

  final Duration timeout;
  final MdnsDiscoveryService? _mdns;
  final Map<String, _ReachabilityEntry> _cache = {};
  static const _cacheTtl = Duration(minutes: 2);

  void injectMdns(MdnsDiscoveryService mdns) {
    // Allow post-construction injection for service locator wiring.
    (_mdnsRef = mdns);
  }

  MdnsDiscoveryService? _mdnsRef;

  MdnsDiscoveryService? get _effectiveMdns => _mdns ?? _mdnsRef;

  /// Checks if the given actor URL (or node base URL) is reachable.
  ///
  /// [publicAddress] — if provided, this is the x-nightingale-public-address
  /// from the cached actor object (STUN-discovered address).
  Future<bool> isReachable(
    String actorOrNodeUrl, {
    String? publicAddress,
  }) async {
    final now = DateTime.now();

    final cacheKey = actorOrNodeUrl;
    final cached = _cache[cacheKey];
    if (cached != null && now.difference(cached.checkedAt) < _cacheTtl) {
      return cached.isReachable;
    }

    // Resolve which URL to actually probe using the priority chain.
    final probeUrl = resolveProbeUrl(actorOrNodeUrl, publicAddress);

    final isReachable = await _probe(probeUrl);
    _cache[cacheKey] = _ReachabilityEntry(
      isReachable: isReachable,
      checkedAt: now,
    );
    return isReachable;
  }

  /// Resolves the URL to probe for [actorOrNodeUrl].
  /// Exposed for testing; prefer [isReachable] in production code.
  String resolveProbeUrl(String actorOrNodeUrl, String? publicAddress) {
    // 1. mDNS cache — use if we have a fresh local peer entry.
    final mdnsPeer = _effectiveMdns?.resolve(actorOrNodeUrl);
    if (mdnsPeer != null) {
      AppLogger.debug(
        'Reachability: using mDNS address for $actorOrNodeUrl → '
        '${mdnsPeer.ip}:${mdnsPeer.port}',
        tag: _tag,
      );
      return 'http://${mdnsPeer.ip}:${mdnsPeer.port}';
    }

    // 2. STUN-discovered public address from the actor object.
    if (publicAddress != null && publicAddress.isNotEmpty) {
      AppLogger.debug(
        'Reachability: using STUN address for $actorOrNodeUrl → $publicAddress',
        tag: _tag,
      );
      return 'http://$publicAddress';
    }

    // 3. Stored actor URL host.
    return _extractBaseUrl(actorOrNodeUrl);
  }

  Future<bool> _probe(String baseUrl) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = timeout;
      final request = await client.headUrl(Uri.parse('$baseUrl/actor'));
      final response = await request.close().timeout(timeout);
      final ok = response.statusCode < 500;
      await response.drain();
      client.close();
      AppLogger.debug('Reachability probe $baseUrl: $ok', tag: _tag);
      return ok;
    } catch (e) {
      AppLogger.debug('Reachability probe $baseUrl failed: $e', tag: _tag);
      return false;
    }
  }

  String _extractBaseUrl(String url) {
    final uri = Uri.parse(url);
    return '${uri.scheme}://${uri.host}'
        '${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
  }

  void clearCache() {
    _cache.clear();
    AppLogger.debug('Reachability cache cleared', tag: _tag);
  }
}

class _ReachabilityEntry {
  _ReachabilityEntry({required this.isReachable, required this.checkedAt});
  final bool isReachable;
  final DateTime checkedAt;
}
