import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/recommendations/domain/recommendation_result.dart';
import 'package:nightingale/features/recommendations/domain/provenance_record.dart';

const _tag = 'global_trending_relay';

/// Fetches trending tracks from a community-operated relay.
/// Returns empty list when opt-in is false or relay is unavailable.
class GlobalTrendingRelayService {
  GlobalTrendingRelayService({
    http.Client? client,
    this.relayEndpoint,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String? relayEndpoint;

  // In-memory session cache — cleared when opt-out happens.
  List<RecommendationResult>? _sessionCache;

  Future<List<RecommendationResult>> fetchTrending({
    required bool optedIn,
  }) async {
    if (!optedIn) return [];

    if (_sessionCache != null) return _sessionCache!;

    final endpoint = relayEndpoint;
    if (endpoint == null || endpoint.isEmpty) return [];

    try {
      final response = await _client
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as List<dynamic>;
      final results = json.map((raw) {
        final map = raw as Map<String, dynamic>;
        final artist = map['artist'] as String? ?? '';
        final title = map['title'] as String? ?? '';
        final fp =
            '${artist.toLowerCase().trim()}:${title.toLowerCase().trim()}';
        return RecommendationResult(
          trackFingerprint: fp,
          trackTitle: title,
          trackArtist: artist,
          score: (map['score'] as num?)?.toDouble() ?? 1.0,
          provenance: const ProvenanceRecord(
            paths: [ScoringPath.coldStart],
            reasonString: 'Trending across the network',
          ),
        );
      }).toList();

      _sessionCache = results;
      return results;
    } catch (e) {
      AppLogger.debug('GlobalTrendingRelayService: error — $e', tag: _tag);
      return [];
    }
  }

  void clearCache() {
    _sessionCache = null;
  }
}
