import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nightingale/core/logging/app_logger.dart';

const _tag = 'node_discovery';

class DiscoveredNode {
  const DiscoveredNode({
    required this.nodeUrl,
    required this.displayName,
    required this.username,
    this.publicAddress,
    this.genreTags = const [],
    this.trackCount = 0,
  });

  final String nodeUrl;
  final String displayName;
  final String username;
  final String? publicAddress;
  final List<String> genreTags;
  final int trackCount;
}

/// Bootstrap discovery directory — maps usernames to reachable node addresses.
///
/// This is NOT a central authority. It is a lightweight introduction server:
/// nodes register themselves on startup so new users with no prior connections
/// can find others by username regardless of network. Once two nodes have
/// exchanged actor objects, they communicate directly with no server involved.
///
/// The server address is set via the DISCOVERY_ENDPOINT build env var.
class NodeDiscoveryService {
  NodeDiscoveryService({
    http.Client? client,
    this.discoveryEndpoint,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String? discoveryEndpoint;

  bool get _hasEndpoint =>
      discoveryEndpoint != null && discoveryEndpoint!.isNotEmpty;

  /// Registers this node with the discovery directory on startup.
  /// Called after the federation server is bound and STUN has resolved.
  Future<void> registerNode({
    required String username,
    required String actorUrl,
    String? publicAddress,
  }) async {
    if (!_hasEndpoint) return;
    try {
      final response = await _client
          .post(
            Uri.parse('$discoveryEndpoint/nodes'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'actorUrl': actorUrl,
              if (publicAddress != null) 'publicAddress': publicAddress,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        AppLogger.debug('Registered with discovery directory', tag: _tag);
      } else {
        AppLogger.debug(
          'Registration returned ${response.statusCode}',
          tag: _tag,
        );
      }
    } catch (e) {
      AppLogger.debug('Registration failed: $e', tag: _tag);
    }
  }

  /// Searches the discovery directory for a node by username.
  Future<DiscoveredNode?> findByUsername(String username) async {
    if (!_hasEndpoint) return null;
    try {
      final uri = Uri.parse('$discoveryEndpoint/nodes')
          .replace(queryParameters: {'username': username});

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);

      // Server may return a single object or a list — handle both.
      final map = body is List
          ? (body.isEmpty ? null : body.first as Map<String, dynamic>)
          : body as Map<String, dynamic>?;

      if (map == null) return null;

      return DiscoveredNode(
        nodeUrl: map['actorUrl'] as String? ?? '',
        displayName: map['displayName'] as String? ?? username,
        username: map['username'] as String? ?? username,
        publicAddress: map['publicAddress'] as String?,
        genreTags: (map['genreTags'] as List<dynamic>?)
                ?.map((g) => g.toString())
                .toList() ??
            [],
        trackCount: map['trackCount'] as int? ?? 0,
      );
    } catch (e) {
      AppLogger.debug('findByUsername failed: $e', tag: _tag);
      return null;
    }
  }

  /// Fetches all discoverable nodes — used for cold-start recommendations.
  Future<List<DiscoveredNode>> fetchDiscoverableNodes() async {
    if (!_hasEndpoint) return [];
    try {
      final response = await _client
          .get(Uri.parse('$discoveryEndpoint/nodes'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as List<dynamic>;
      return json.map((raw) {
        final map = raw as Map<String, dynamic>;
        return DiscoveredNode(
          nodeUrl: map['actorUrl'] as String? ?? map['nodeUrl'] as String? ?? '',
          displayName: map['displayName'] as String? ?? '',
          username: map['username'] as String? ?? '',
          publicAddress: map['publicAddress'] as String?,
          genreTags: (map['genreTags'] as List<dynamic>?)
                  ?.map((g) => g.toString())
                  .toList() ??
              [],
          trackCount: map['trackCount'] as int? ?? 0,
        );
      }).where((n) => n.nodeUrl.isNotEmpty).toList();
    } catch (e) {
      AppLogger.debug('fetchDiscoverableNodes failed: $e', tag: _tag);
      return [];
    }
  }
}
