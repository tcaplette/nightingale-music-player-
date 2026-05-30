import 'dart:async';
import 'dart:io';

import 'package:nightingale/core/logging/app_logger.dart';

const _tag = 'reachability';

/// Checks if a remote node is reachable.
class NodeReachabilityService {
  NodeReachabilityService({
    this.timeout = const Duration(seconds: 5),
  });

  final Duration timeout;
  final Map<String, _ReachabilityEntry> _cache = {};
  static const _cacheTtl = Duration(minutes: 2);

  /// Checks if the given actor URL (or node base URL) is reachable.
  Future<bool> isReachable(String actorOrNodeUrl) async {
    final now = DateTime.now();

    // Check cache
    final cached = _cache[actorOrNodeUrl];
    if (cached != null && now.difference(cached.checkedAt) < _cacheTtl) {
      return cached.isReachable;
    }

    // Extract base URL from actor URL
    final baseUrl = _extractBaseUrl(actorOrNodeUrl);

    try {
      // Try a HEAD request to the node
      final client = HttpClient();
      client.connectionTimeout = timeout;
      final request = await client.headUrl(Uri.parse('$baseUrl/actor'));
      final response = await request.close().timeout(timeout);
      final isReachable = response.statusCode < 500;
      await response.drain(); // discard body
      client.close();

      _cache[actorOrNodeUrl] = _ReachabilityEntry(
        isReachable: isReachable,
        checkedAt: now,
      );

      AppLogger.debug('Reachability check for $baseUrl: $isReachable', tag: _tag);
      return isReachable;
    } catch (e) {
      _cache[actorOrNodeUrl] = _ReachabilityEntry(
        isReachable: false,
        checkedAt: now,
      );
      AppLogger.debug('Reachability check for $baseUrl failed: $e', tag: _tag);
      return false;
    }
  }

  String _extractBaseUrl(String url) {
    final uri = Uri.parse(url);
    return '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
  }

  void clearCache() {
    _cache.clear();
  }
}

class _ReachabilityEntry {
  _ReachabilityEntry({required this.isReachable, required this.checkedAt});
  final bool isReachable;
  final DateTime checkedAt;
}
