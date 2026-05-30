enum ScoringPath { trending, affinity, newFromKnown, coldStart }

class ProvenanceRecord {
  const ProvenanceRecord({
    required this.paths,
    this.topActorId,
    this.topActorDisplayName,
    required this.reasonString,
  });

  final List<ScoringPath> paths;

  // The primary human contributor — display name, never a raw handle.
  final String? topActorId;
  final String? topActorDisplayName;

  // Pre-rendered human-readable reason string, e.g.:
  //   "Maya has had this on repeat"
  //   "3 people you follow saved this"
  //   "New from Massive Attack, in your library"
  final String reasonString;

  ProvenanceRecord copyWith({
    List<ScoringPath>? paths,
    String? topActorId,
    String? topActorDisplayName,
    String? reasonString,
  }) =>
      ProvenanceRecord(
        paths: paths ?? this.paths,
        topActorId: topActorId ?? this.topActorId,
        topActorDisplayName: topActorDisplayName ?? this.topActorDisplayName,
        reasonString: reasonString ?? this.reasonString,
      );
}
