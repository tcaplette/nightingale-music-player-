import 'dart:math';

import 'package:nightingale/features/recommendations/domain/provenance_record.dart';
import 'package:nightingale/features/recommendations/domain/recommendation_result.dart';
import 'package:nightingale/features/recommendations/domain/signal_event.dart';

const _kMinLocalSignals = 10;

/// Computes cosine similarity between the local taste vector and each followed
/// node's observable taste vector (from their network_listen + network_like
/// signals). Surfaces tracks saved/liked by high-affinity nodes.
class TasteAffinityScorer {
  /// [localScores]: fingerprint → taste score from local signal store.
  /// [networkEvents]: all recent network events from followed nodes.
  /// [actorDisplayNames]: actorId → display name for provenance strings.
  /// [ownedFingerprints]: fingerprints already in local library (excluded).
  List<RecommendationResult> score({
    required Map<String, double> localScores,
    required List<SignalEvent> networkEvents,
    required Map<String, String> actorDisplayNames,
    required Set<String> ownedFingerprints,
  }) {
    if (localScores.length < _kMinLocalSignals) return [];

    // Build per-actor listen vectors: actorId → {fingerprint: count}
    final actorVectors = <String, Map<String, double>>{};
    for (final event in networkEvents) {
      final actor = event.sourceActorId;
      if (actor == null) continue;
      actorVectors
          .putIfAbsent(actor, () => {})
          .update(event.trackFingerprint, (v) => v + 1, ifAbsent: () => 1);
    }

    // Compute affinity for each actor
    final affinityScores = <String, double>{};
    for (final entry in actorVectors.entries) {
      affinityScores[entry.key] =
          _cosine(localScores, entry.value);
    }

    // Surface tracks listened to / liked by high-affinity actors
    // that the user doesn't already own
    final seen = <String>{};
    final results = <RecommendationResult>[];

    final sortedActors = actorVectors.keys.toList()
      ..sort(
          (a, b) => (affinityScores[b] ?? 0).compareTo(affinityScores[a] ?? 0));

    for (final actor in sortedActors) {
      final affinity = affinityScores[actor] ?? 0;
      if (affinity <= 0) continue;

      final displayName =
          actorDisplayNames[actor] ?? 'Someone you follow';

      for (final fp in actorVectors[actor]!.keys) {
        if (ownedFingerprints.contains(fp)) continue;
        if (seen.contains(fp)) continue;
        seen.add(fp);

        final parts = fp.split(':');
        final artist = parts.isNotEmpty
            ? _capitalize(parts[0])
            : 'Unknown Artist';
        final title = parts.length > 1
            ? _capitalize(parts[1])
            : 'Unknown Track';

        results.add(RecommendationResult(
          trackFingerprint: fp,
          trackTitle: title,
          trackArtist: artist,
          score: affinity,
          provenance: ProvenanceRecord(
            paths: [ScoringPath.affinity],
            topActorId: actor,
            topActorDisplayName: displayName,
            reasonString: '$displayName has been saving this',
          ),
        ));
      }
    }

    return results;
  }

  /// Public for the affinity matrix debug viewer.
  Map<String, double> computeAffinityMatrix({
    required Map<String, double> localScores,
    required List<SignalEvent> networkEvents,
  }) {
    final actorVectors = <String, Map<String, double>>{};
    for (final event in networkEvents) {
      final actor = event.sourceActorId;
      if (actor == null) continue;
      actorVectors
          .putIfAbsent(actor, () => {})
          .update(event.trackFingerprint, (v) => v + 1, ifAbsent: () => 1);
    }
    return {
      for (final entry in actorVectors.entries)
        entry.key: _cosine(localScores, entry.value),
    };
  }

  bool get requiresSufficientSignals => true;

  double _cosine(Map<String, double> a, Map<String, double> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (final fp in a.keys) {
      normA += a[fp]! * a[fp]!;
      final bv = b[fp];
      if (bv != null) dot += a[fp]! * bv;
    }
    for (final v in b.values) {
      normB += v * v;
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
