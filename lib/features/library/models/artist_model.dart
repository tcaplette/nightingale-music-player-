class ArtistModel {
  const ArtistModel({required this.name, this.albumCount = 0});

  final String name;
  final int albumCount;

  @override
  bool operator ==(Object other) => other is ArtistModel && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
