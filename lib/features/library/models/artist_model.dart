class ArtistModel {
  const ArtistModel({
    required this.id,
    required this.name,
    this.albumCount = 0,
  });

  final int id;
  final String name;
  final int albumCount;

  @override
  bool operator ==(Object other) => other is ArtistModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
