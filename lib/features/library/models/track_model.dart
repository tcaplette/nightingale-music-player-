import 'package:nightingale/core/database/app_database.dart';

class TrackModel {
  const TrackModel({
    required this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    this.albumId,
    this.albumName,
    this.albumArtist,
    this.trackNumber,
    this.discNumber,
    this.genre,
    this.releaseYear,
    required this.durationMs,
    this.artworkPath,
    required this.dateAdded,
    // Phase 4: federation fields
    this.sourceActorUrl,
    this.streamUrl,
    this.isReachable = true,
  });

  final int id;
  final String filePath;
  final String title;
  final String artist;
  final int? albumId;
  final String? albumName;
  final String? albumArtist;
  final int? trackNumber;
  final int? discNumber;
  final String? genre;
  final int? releaseYear;
  final int durationMs;
  final String? artworkPath;
  final DateTime dateAdded;

  // Phase 4: federation fields
  final String? sourceActorUrl; // null = local track
  final String? streamUrl; // remote stream URL
  final bool isReachable; // false = host offline

  Duration get duration => Duration(milliseconds: durationMs);

  bool get isRemote => sourceActorUrl != null;

  factory TrackModel.fromRow(TracksTableData row, {String? albumName}) {
    return TrackModel(
      id: row.id,
      filePath: row.filePath,
      title: row.title,
      artist: row.artist,
      albumId: row.albumId,
      albumName: albumName,
      albumArtist: row.albumArtist,
      trackNumber: row.trackNumber,
      discNumber: row.discNumber,
      genre: row.genre,
      releaseYear: row.releaseYear,
      durationMs: row.durationMs,
      artworkPath: row.artworkPath,
      dateAdded: row.dateAdded,
    );
  }

  @override
  bool operator ==(Object other) => other is TrackModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
