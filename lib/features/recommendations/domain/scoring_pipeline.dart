import 'package:nightingale/features/recommendations/domain/network_trending_scorer.dart';
import 'package:nightingale/features/recommendations/domain/new_from_known_scorer.dart';
import 'package:nightingale/features/recommendations/domain/provenance_record.dart';
import 'package:nightingale/features/recommendations/domain/recommendation_result.dart';
import 'package:nightingale/features/recommendations/domain/signal_event.dart';
import 'package:nightingale/features/recommendations/domain/taste_affinity_scorer.dart';

const _kMinFollowCount = 1;

class ScoringInput {
  const ScoringInput({
    required this.localScores,
    required this.networkEvents,
    required this.actorDisplayNames,
    required this.localArtistsNormalized,
    required this.ownedFingerprints,
    required this.followingCount,
    this.seedArtist,
  });

  final Map<String, double> localScores;
  final List<SignalEvent> networkEvents;
  final Map<String, String> actorDisplayNames;
  final Set<String> localArtistsNormalized;
  final Set<String> ownedFingerprints;
  final int followingCount;
  final String? seedArtist;
}

class ScoringPipeline {
  ScoringPipeline({
    NetworkTrendingScorer? trending,
    TasteAffinityScorer? affinity,
    NewFromKnownScorer? newFromKnown,
  })  : _trending = trending ?? NetworkTrendingScorer(),
        _affinity = affinity ?? TasteAffinityScorer(),
        _newFromKnown = newFromKnown ?? NewFromKnownScorer();

  final NetworkTrendingScorer _trending;
  final TasteAffinityScorer _affinity;
  final NewFromKnownScorer _newFromKnown;

  List<RecommendationResult> run(ScoringInput input) {
    if (input.followingCount < _kMinFollowCount || input.networkEvents.isEmpty) {
      return [];
    }

    final trendingResults = _trending.score(
      networkEvents: input.networkEvents,
      actorDisplayNames: input.actorDisplayNames,
      ownedFingerprints: input.ownedFingerprints,
    );

    final affinityResults = _affinity.score(
      localScores: input.localScores,
      networkEvents: input.networkEvents,
      actorDisplayNames: input.actorDisplayNames,
      ownedFingerprints: input.ownedFingerprints,
    );

    final newFromKnownResults = _newFromKnown.score(
      localArtistsNormalized: input.localArtistsNormalized,
      networkEvents: input.networkEvents,
      ownedFingerprints: input.ownedFingerprints,
    );

    var merged = _merge([trendingResults, affinityResults, newFromKnownResults]);

    if (input.seedArtist != null) {
      final seed = input.seedArtist!.toLowerCase();
      merged = (merged.map((r) {
        if (r.trackArtist.toLowerCase() == seed) {
          return r.copyWith(score: r.score * 2.0);
        }
        return r;
      }).toList()
        ..sort((a, b) => b.score.compareTo(a.score)));
    }

    return merged;
  }

  Map<String, double> computeAffinityMatrix(ScoringInput input) =>
      _affinity.computeAffinityMatrix(
        localScores: input.localScores,
        networkEvents: input.networkEvents,
      );

  List<RecommendationResult> _merge(
      List<List<RecommendationResult>> pathResults) {
    // Merge by fingerprint — sum scores, union paths, keep best provenance
    final byFingerprint = <String, RecommendationResult>{};

    for (final list in pathResults) {
      for (final result in list) {
        final existing = byFingerprint[result.trackFingerprint];
        if (existing == null) {
          byFingerprint[result.trackFingerprint] = result;
        } else {
          final mergedPaths = {
            ...existing.provenance.paths,
            ...result.provenance.paths,
          }.toList();
          final mergedScore = existing.score + result.score;
          final betterProvenance = result.score > existing.score
              ? result.provenance
              : existing.provenance;
          byFingerprint[result.trackFingerprint] = existing.copyWith(
            score: mergedScore,
            provenance: betterProvenance.copyWith(paths: mergedPaths),
          );
        }
      }
    }

    final merged = byFingerprint.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return merged;
  }
}
