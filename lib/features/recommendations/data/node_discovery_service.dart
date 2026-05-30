import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nightingale/core/logging/app_logger.dart';

const _tag = 'node_discovery';

class DiscoveredNode {
  const DiscoveredNode({
    required this.nodeUrl,
    required this.displayName,
    this.genreTags = const [],
    this.trackCount = 0,
  });

  final String nodeUrl;
  final String displayName;
  final List<String> genreTags;
  final int trackCount;
}

/// Fetches a list of nodes that have opted in to being discoverable.
/// Request contains no user-identifying data — unauthenticated GET only.
class NodeDiscoveryService {
  NodeDiscoveryService({
    http.Client? client,
    this.discoveryEndpoint,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String? discoveryEndpoint;

  Future<List<DiscoveredNode>> fetchDiscoverableNodes() async {
    final endpoint = discoveryEndpoint;
    if (endpoint == null || endpoint.isEmpty) return [];

    try {
      // No Authorization header, no user data in the request.
      final response = await _client
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        AppLogger.debug(
          'NodeDiscoveryService: non-200 response (${response.statusCode})',
          tag: _tag,
        );
        return [];
      }

      final json = jsonDecode(response.body) as List<dynamic>;
      return json.map((raw) {
        final map = raw as Map<String, dynamic>;
        return DiscoveredNode(
          nodeUrl: map['nodeUrl'] as String? ?? '',
          displayName: map['displayName'] as String? ?? 'Unknown',
          genreTags: (map['genreTags'] as List<dynamic>?)
                  ?.map((g) => g.toString())
                  .toList() ??
              [],
          trackCount: map['trackCount'] as int? ?? 0,
        );
      }).where((n) => n.nodeUrl.isNotEmpty).toList();
    } catch (e) {
      AppLogger.debug('NodeDiscoveryService: error — $e', tag: _tag);
      return [];
    }
  }
}
