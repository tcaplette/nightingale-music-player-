import 'dart:convert';

import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/recommendations/data/cold_start_settings_repository.dart';
import 'package:nightingale/features/recommendations/data/global_trending_relay_service.dart';
import 'package:nightingale/features/recommendations/data/node_discovery_service.dart';
import 'package:nightingale/features/recommendations/domain/provenance_record.dart';
import 'package:nightingale/features/recommendations/domain/recommendation_result.dart';

const _tag = 'cold_start';

class ColdStartRepository {
  ColdStartRepository({
    required AppDatabase db,
    required ColdStartSettingsRepository settings,
    required NodeDiscoveryService discovery,
    required GlobalTrendingRelayService relay,
  })  : _db = db,
        _settings = settings,
        _discovery = discovery,
        _relay = relay;

  final AppDatabase _db;
  final ColdStartSettingsRepository _settings;
  final NodeDiscoveryService _discovery;
  final GlobalTrendingRelayService _relay;

  Future<List<RecommendationResult>> getBootstrapResults() async {
    AppLogger.debug('ColdStartRepository.getBootstrapResults', tag: _tag);

    final results = <RecommendationResult>[];

    // 1. Genre/library overlap — fully offline, uses cached remote library data
    final genreResults = await _genreOverlapResults();
    results.addAll(genreResults);

    // 2. Server-light node discovery (no user data sent)
    final discoveryEnabled = await _settings.isDiscoveryEnabled();
    if (discoveryEnabled) {
      final discovered = await _discovery.fetchDiscoverableNodes();
      for (final node in discovered) {
        if (node.genreTags.isEmpty) continue;
        results.add(RecommendationResult(
          trackFingerprint: 'node:${node.nodeUrl}',
          trackTitle: 'Follow ${node.displayName}',
          trackArtist: node.genreTags.take(2).join(', '),
          score: 0.5,
          hostNodeUrl: node.nodeUrl,
          provenance: ProvenanceRecord(
            paths: [ScoringPath.coldStart],
            reasonString:
                'Active node with music you might like (${node.trackCount} tracks)',
          ),
        ));
      }
    }

    // 3. Opt-in global trending relay
    final trendingEnabled = await _settings.isGlobalTrendingEnabled();
    final trendingResults = await _relay.fetchTrending(optedIn: trendingEnabled);
    results.addAll(trendingResults);

    AppLogger.debug(
      'ColdStartRepository: ${results.length} bootstrap results',
      tag: _tag,
    );
    return results;
  }

  Future<List<RecommendationResult>> _genreOverlapResults() async {
    // Extract genres from local library
    final localTracks = await (
      _db.select(_db.tracksTable)..where((t) => t.genre.isNotNull())
    ).get();
    final localGenres = localTracks
        .map((t) => t.genre!.toLowerCase().trim())
        .where((g) => g.isNotEmpty)
        .toSet();

    // Match against cached remote library metadata
    final remoteCaches = await _db.select(_db.remoteLibrariesTable).get();
    if (remoteCaches.isEmpty) return [];

    final results = <RecommendationResult>[];

    for (final cache in remoteCaches) {
      try {
        final collection =
            jsonDecode(cache.collectionJson) as Map<String, dynamic>;
        final items = collection['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final map = item as Map<String, dynamic>;
          final genre = (map['genre'] as String? ?? '').toLowerCase().trim();
          // When the user has local music: skip tracks whose genre is known and
          // doesn't match. When the user has no local music at all: include
          // everything from the network (new user cold-start).
          if (localGenres.isNotEmpty &&
              genre.isNotEmpty &&
              !localGenres.contains(genre)) continue;
          final artist = map['artist'] as String? ?? '';
          final title = map['name'] as String? ?? '';
          if (artist.isEmpty || title.isEmpty) continue;
          final fp =
              '${artist.toLowerCase().trim()}:${title.toLowerCase().trim()}';
          final streamUrl = map['stream_url'] as String?;
          final reasonString = localGenres.isNotEmpty && genre.isNotEmpty
              ? 'Matches your $genre library'
              : 'From someone you follow';
          results.add(RecommendationResult(
            trackFingerprint: fp,
            trackTitle: title,
            trackArtist: artist,
            score: 0.8,
            hostNodeUrl: cache.actorUrl,
            streamUrl: streamUrl,
            provenance: ProvenanceRecord(
              paths: [ScoringPath.coldStart],
              reasonString: reasonString,
            ),
          ));
        }
      } catch (_) {}
    }

    return results;
  }
}
