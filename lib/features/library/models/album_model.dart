class AlbumModel {
  const AlbumModel({
    required this.name,
    required this.artist,
    this.artworkPath,
    this.releaseYear,
    required this.trackCount,
    this.includedTrackCount = 0,
  });

  final String name;
  final String artist;
  final String? artworkPath;
  final int? releaseYear;
  final int trackCount;
  final int includedTrackCount;

  @override
  bool operator ==(Object other) =>
      other is AlbumModel && other.name == name && other.artist == artist;

  @override
  int get hashCode => Object.hash(name, artist);
}
