import 'package:nightingale/features/recommendations/domain/provenance_record.dart';
import 'package:nightingale/features/recommendations/domain/recommendation_result.dart';
import 'package:nightingale/features/recommendations/domain/signal_event.dart';

const _kTrendingWindow = Duration(days: 7);

/// Scores tracks by how many distinct followed nodes listened to them in the
/// past 7 days. Each followed node counts once per track, regardless of
/// how many times they listened.
class NetworkTrendingScorer {
  List<RecommendationResult> score({
    required List<SignalEvent> networkEvents,
    required Map<String, String> actorDisplayNames, // actorId → displayName
    required Set<String> ownedFingerprints,
  }) {
    final cutoff = DateTime.now().toUtc().subtract(_kTrendingWindow);

    // group: fingerprint → Set<actorId> (distinct actors in window)
    final actorsByTrack = <String, Set<String>>{};
    // group: fingerprint → top actor (first one found)
    final topActorByTrack = <String, String>{};
    // group: fingerprint → title/artist from events (first seen)
    final metaByTrack = <String, ({String title, String artist})>{};

    for (final event in networkEvents) {
      if (event.timestampUtc.isBefore(cutoff)) continue;
      if (event.eventType != SignalEventType.networkListen) continue;
      if (event.sourceActorId == null) continue;
      final fp = event.trackFingerprint;
      if (ownedFingerprints.contains(fp)) continue;

      actorsByTrack.putIfAbsent(fp, () => {}).add(event.sourceActorId!);
      if (!topActorByTrack.containsKey(fp)) {
        topActorByTrack[fp] = event.sourceActorId!;
      }

      if (!metaByTrack.containsKey(fp)) {
        final parts = fp.split(':');
        metaByTrack[fp] = (
          artist: parts.isNotEmpty ? _capitalize(parts[0]) : 'Unknown Artist',
          title: parts.length > 1 ? _capitalize(parts[1]) : 'Unknown Track',
        );
      }
    }

    final results = <RecommendationResult>[];

    for (final entry in actorsByTrack.entries) {
      final fp = entry.key;
      final actors = entry.value;
      final count = actors.length;
      final topActor = topActorByTrack[fp];
      final topName = topActor != null
          ? (actorDisplayNames[topActor] ?? 'Someone you follow')
          : null;
      final meta = metaByTrack[fp]!;

      final reasonString = count == 1
          ? '${topName ?? 'Someone you follow'} has been playing this'
          : '$count people you follow have been playing this';

      results.add(RecommendationResult(
        trackFingerprint: fp,
        trackTitle: meta.title,
        trackArtist: meta.artist,
        score: count.toDouble(),
        provenance: ProvenanceRecord(
          paths: [ScoringPath.trending],
          topActorId: topActor,
          topActorDisplayName: topName,
          reasonString: reasonString,
        ),
      ));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }
}
