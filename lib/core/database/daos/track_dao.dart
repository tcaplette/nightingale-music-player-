import 'package:drift/drift.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/database/tables/tracks_table.dart';

part 'track_dao.g.dart';

@DriftAccessor(tables: [TracksTable])
class TrackDao extends DatabaseAccessor<AppDatabase> with _$TrackDaoMixin {
  TrackDao(super.db);

  Future<List<TracksTableData>> getAllTracks() =>
      (select(tracksTable)..orderBy([(t) => OrderingTerm.asc(t.title)])).get();

  Stream<List<TracksTableData>> watchAllTracks() =>
      (select(tracksTable)..orderBy([(t) => OrderingTerm.asc(t.title)])).watch();

  Future<List<TracksTableData>> getTracksByAlbum(int albumId) =>
      (select(tracksTable)
            ..where((t) => t.albumId.equals(albumId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.discNumber),
              (t) => OrderingTerm.asc(t.trackNumber),
            ]))
          .get();

  Stream<List<TracksTableData>> watchTracksByAlbum(int albumId) =>
      (select(tracksTable)
            ..where((t) => t.albumId.equals(albumId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.discNumber),
              (t) => OrderingTerm.asc(t.trackNumber),
            ]))
          .watch();

  Future<List<TracksTableData>> getTracksByArtist(String artist) =>
      (select(tracksTable)
            ..where((t) => t.artist.equals(artist))
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .get();

  Future<List<TracksTableData>> getTracksByGenre(String genre) =>
      (select(tracksTable)
            ..where((t) => t.genre.lower().equals(genre.toLowerCase()))
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .get();

  Future<List<TracksTableData>> searchTracks(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(tracksTable)
          ..where(
            (t) =>
                t.title.lower().like(q) |
                t.artist.lower().like(q) |
                t.genre.lower().like(q),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.title)]))
        .get();
  }

  Future<TracksTableData?> getTrackByFilePath(String filePath) =>
      (select(tracksTable)..where((t) => t.filePath.equals(filePath)))
          .getSingleOrNull();

  Future<Set<String>> getAllFilePaths() async {
    final rows = await (select(tracksTable)..orderBy([])).get();
    return rows.map((r) => r.filePath).toSet();
  }

  Future<int> insertTrack(TracksTableCompanion track) =>
      into(tracksTable).insertOnConflictUpdate(track);

  Future<bool> updateTrack(TracksTableCompanion track) =>
      update(tracksTable).replace(track);

  Future<int> deleteTrackByFilePath(String filePath) =>
      (delete(tracksTable)..where((t) => t.filePath.equals(filePath))).go();

  Future<void> deleteTracksWithFilePaths(Set<String> filePaths) async {
    for (final path in filePaths) {
      await deleteTrackByFilePath(path);
    }
  }
}
