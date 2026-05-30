import 'package:nightingale/features/recommendations/domain/provenance_record.dart';

class RecommendationResult {
  const RecommendationResult({
    required this.trackFingerprint,
    required this.trackTitle,
    required this.trackArtist,
    this.trackArtworkUrl,
    this.hostNodeUrl,
    this.streamUrl,
    required this.score,
    required this.provenance,
  });

  final String trackFingerprint;
  final String trackTitle;
  final String trackArtist;
  final String? trackArtworkUrl;
  final String? hostNodeUrl;
  final String? streamUrl;
  final double score;
  final ProvenanceRecord provenance;

  RecommendationResult copyWith({double? score, ProvenanceRecord? provenance}) =>
      RecommendationResult(
        trackFingerprint: trackFingerprint,
        trackTitle: trackTitle,
        trackArtist: trackArtist,
        trackArtworkUrl: trackArtworkUrl,
        hostNodeUrl: hostNodeUrl,
        streamUrl: streamUrl,
        score: score ?? this.score,
        provenance: provenance ?? this.provenance,
      );
}
