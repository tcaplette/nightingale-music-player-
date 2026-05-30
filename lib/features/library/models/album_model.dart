import 'package:nightingale/core/database/app_database.dart';

class AlbumModel {
  const AlbumModel({
    required this.id,
    required this.name,
    required this.artist,
    this.artworkPath,
    this.releaseYear,
    required this.trackCount,
  });

  final int id;
  final String name;
  final String artist;
  final String? artworkPath;
  final int? releaseYear;
  final int trackCount;

  factory AlbumModel.fromRow(AlbumsTableData row) {
    return AlbumModel(
      id: row.id,
      name: row.name,
      artist: row.artist,
      artworkPath: row.artworkPath,
      releaseYear: row.releaseYear,
      trackCount: row.trackCount,
    );
  }

  @override
  bool operator ==(Object other) => other is AlbumModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
