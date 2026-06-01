import 'package:drift/drift.dart' show Value;
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
    // Read-only from file tags; never user-entered
    this.isrc,
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

  // Metadata: read-only from TSRC (ID3v2) / ISRC= (Vorbis); never user-entered
  final String? isrc;

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
      isrc: row.isrc,
    );
  }

  TracksTableCompanion toUpdateCompanion() {
    return TracksTableCompanion(
      id: Value(id),
      filePath: Value(filePath),
      title: Value(title),
      artist: Value(artist),
      albumId: Value(albumId),
      albumArtist: Value(albumArtist),
      trackNumber: Value(trackNumber),
      discNumber: Value(discNumber),
      genre: Value(genre),
      releaseYear: Value(releaseYear),
      durationMs: Value(durationMs),
      artworkPath: Value(artworkPath),
      isrc: Value(isrc),
    );
  }

  @override
  bool operator ==(Object other) => other is TrackModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
