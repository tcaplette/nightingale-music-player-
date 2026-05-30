import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/repositories/social_repository.dart';
import 'package:nightingale/features/library/library_repository.dart';
import 'package:nightingale/features/recommendations/data/signal_repository.dart';
import 'package:nightingale/features/recommendations/domain/cold_start_repository.dart';
import 'package:nightingale/features/recommendations/domain/recommendation_result.dart';
import 'package:nightingale/features/recommendations/domain/scoring_pipeline.dart';
import 'package:nightingale/features/recommendations/domain/signal_event.dart';
import 'package:nightingale/features/recommendations/domain/taste_affinity_scorer.dart';

const _kMinFollowCount = 1;
const _kRescoreMinInterval = Duration(minutes: 30);

class EngineState {
  const EngineState({
    required this.results,
    required this.lastScoredAt,
    this.usedColdStart = false,
    this.affinityMatrix = const {},
  });

  final List<RecommendationResult> results;
  final DateTime lastScoredAt;
  final bool usedColdStart;
  final Map<String, double> affinityMatrix;

  static final empty = EngineState(
    results: const [],
    lastScoredAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}

class RecommendationEngineNotifier
    extends AsyncNotifier<EngineState> {
  @override
  Future<EngineState> build() async {
    return EngineState.empty;
  }

  /// Runs a full scoring pass in a background isolate.
  Future<void> rescore({bool force = false}) async {
    final current = state.valueOrNull;
    if (!force && current != null) {
      final elapsed = DateTime.now().toUtc().difference(current.lastScoredAt);
      if (elapsed < _kRescoreMinInterval) return;
    }

    state = const AsyncLoading();

    try {
      final result = await compute(_runScoring, await _buildInput());
      state = AsyncData(result);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<_ScoringInputPayload> _buildInput() async {
    final signalRepo = sl<SignalRepository>();
    final socialRepo = sl<SocialRepository>();
    final libraryRepo = sl<LibraryRepository>();
    final coldStartRepo = sl<ColdStartRepository>();

    final following = await socialRepo.getFollowing();
    final followingCount = following.length;
    final actorIds = following.map((f) => f.remoteActorUrl).toList();

    final localScores = await signalRepo.getAllScores();
    final networkEvents = await signalRepo.getRecentNetworkEvents(
      window: const Duration(days: 7),
      actorIds: actorIds,
    );

    // Resolve display names from actor cache
    final db = sl<AppDatabase>();
    final actorCacheRows = await db.select(db.actorCacheTable).get();
    final actorDisplayNames = <String, String>{};
    for (final row in actorCacheRows) {
      try {
        final json = row.actorJson;
        // Extract preferred display name from cached actor JSON
        final nameMatch = RegExp(r'"(?:name|preferredUsername)"\s*:\s*"([^"]+)"')
            .firstMatch(json);
        if (nameMatch != null) {
          actorDisplayNames[row.actorUrl] = nameMatch.group(1)!;
        }
      } catch (_) {}
    }

    final allTracks = await libraryRepo.getAllTracks();
    final localArtists = allTracks
        .map((t) => t.artist.toLowerCase().trim())
        .where((a) => a.isNotEmpty && a != 'unknown artist')
        .toSet();
    final ownedFingerprints = allTracks
        .map((t) =>
            '${t.artist.toLowerCase().trim()}:${t.title.toLowerCase().trim()}')
        .toSet();

    final coldStart = followingCount < _kMinFollowCount || networkEvents.isEmpty;

    List<RecommendationResult> coldStartResults = [];
    if (coldStart) {
      coldStartResults = await coldStartRepo.getBootstrapResults();
    }

    return _ScoringInputPayload(
      localScores: localScores,
      networkEvents: networkEvents,
      actorDisplayNames: actorDisplayNames,
      localArtistsNormalized: localArtists,
      ownedFingerprints: ownedFingerprints,
      followingCount: followingCount,
      coldStart: coldStart,
      coldStartResults: coldStartResults,
    );
  }
}

// Top-level function required by compute() — must be static/free function.
EngineState _runScoring(_ScoringInputPayload payload) {
  if (payload.coldStart) {
    return EngineState(
      results: payload.coldStartResults,
      lastScoredAt: DateTime.now().toUtc(),
      usedColdStart: true,
    );
  }

  final pipeline = ScoringPipeline();
  final input = ScoringInput(
    localScores: payload.localScores,
    networkEvents: payload.networkEvents,
    actorDisplayNames: payload.actorDisplayNames,
    localArtistsNormalized: payload.localArtistsNormalized,
    ownedFingerprints: payload.ownedFingerprints,
    followingCount: payload.followingCount,
  );

  final results = pipeline.run(input);
  final affinityMatrix = pipeline.computeAffinityMatrix(input);

  return EngineState(
    results: results,
    lastScoredAt: DateTime.now().toUtc(),
    usedColdStart: false,
    affinityMatrix: affinityMatrix,
  );
}

class _ScoringInputPayload {
  const _ScoringInputPayload({
    required this.localScores,
    required this.networkEvents,
    required this.actorDisplayNames,
    required this.localArtistsNormalized,
    required this.ownedFingerprints,
    required this.followingCount,
    required this.coldStart,
    required this.coldStartResults,
  });

  final Map<String, double> localScores;
  final List<SignalEvent> networkEvents;
  final Map<String, String> actorDisplayNames;
  final Set<String> localArtistsNormalized;
  final Set<String> ownedFingerprints;
  final int followingCount;
  final bool coldStart;
  final List<RecommendationResult> coldStartResults;
}

final recommendationEngineProvider =
    AsyncNotifierProvider<RecommendationEngineNotifier, EngineState>(
  RecommendationEngineNotifier.new,
);
