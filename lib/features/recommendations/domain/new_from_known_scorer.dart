import 'package:nightingale/features/recommendations/domain/provenance_record.dart';
import 'package:nightingale/features/recommendations/domain/recommendation_result.dart';
import 'package:nightingale/features/recommendations/domain/signal_event.dart';

/// Surfaces tracks by artists already present in the user's local library that
/// have been heard on the network but aren't yet in the local library.
class NewFromKnownScorer {
  List<RecommendationResult> score({
    required Set<String> localArtistsNormalized,
    required List<SignalEvent> networkEvents,
    required Set<String> ownedFingerprints,
  }) {
    if (localArtistsNormalized.isEmpty) return [];

    final seen = <String>{};
    final results = <RecommendationResult>[];

    for (final event in networkEvents) {
      final fp = event.trackFingerprint;
      if (ownedFingerprints.contains(fp)) continue;
      if (seen.contains(fp)) continue;

      final parts = fp.split(':');
      if (parts.length < 2) continue;
      final artistNorm = parts[0].trim().toLowerCase();
      final title = _capitalize(parts[1]);
      final artist = _capitalize(artistNorm);

      if (!localArtistsNormalized.contains(artistNorm)) continue;

      seen.add(fp);
      results.add(RecommendationResult(
        trackFingerprint: fp,
        trackTitle: title,
        trackArtist: artist,
        score: 1.0,
        provenance: ProvenanceRecord(
          paths: [ScoringPath.newFromKnown],
          reasonString: 'New from $artist, in your library',
        ),
      ));
    }

    return results;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
