import 'package:drift/drift.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/database/tables/tracks_table.dart';

part 'track_dao.g.dart';

@DriftAccessor(tables: [TracksTable])
class TrackDao extends DatabaseAccessor<AppDatabase> with _$TrackDaoMixin {
  TrackDao(super.db);

  // ── Library queries (isIncluded = true only) ───────────────────────────────

  Future<List<TracksTableData>> getAllTracks() =>
      (select(tracksTable)
            ..where((t) => t.isIncluded.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .get();

  Stream<List<TracksTableData>> watchAllTracks() =>
      (select(tracksTable)
            ..where((t) => t.isIncluded.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .watch();

  // ── Discovered queries (all tracks, no inclusion filter) ───────────────────

  Future<List<TracksTableData>> getAllDiscoveredTracks() =>
      (select(tracksTable)..orderBy([(t) => OrderingTerm.asc(t.title)])).get();

  Stream<List<TracksTableData>> watchAllDiscoveredTracks() =>
      (select(tracksTable)..orderBy([(t) => OrderingTerm.asc(t.title)])).watch();

  Future<int> getDiscoveredTrackCount() async {
    final countExpr = tracksTable.id.count();
    final query = selectOnly(tracksTable)
      ..addColumns([countExpr])
      ..where(tracksTable.isIncluded.equals(false));
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  // ── Inclusion mutations ────────────────────────────────────────────────────

  Future<void> setTrackIncluded(int trackId, bool included) =>
      (update(tracksTable)..where((t) => t.id.equals(trackId)))
          .write(TracksTableCompanion(isIncluded: Value(included)));

  Future<void> setAlbumTracksIncluded(
    String albumName,
    String? albumArtist,
    bool included,
  ) {
    final query = update(tracksTable);
    if (albumArtist == null) {
      query.where((t) => t.albumName.equals(albumName));
    } else {
      query.where(
        (t) => t.albumName.equals(albumName) & t.artist.equals(albumArtist),
      );
    }
    return query.write(TracksTableCompanion(isIncluded: Value(included)));
  }

  Future<void> setAllTracksIncluded(bool included) =>
      update(tracksTable).write(TracksTableCompanion(isIncluded: Value(included)));

  // ── Album / artist / genre queries (name-based) ────────────────────────────

  Future<List<TracksTableData>> getTracksByAlbumName(
    String albumName,
    String? albumArtist,
  ) {
    final query = select(tracksTable)
      ..orderBy([
        (t) => OrderingTerm.asc(t.discNumber),
        (t) => OrderingTerm.asc(t.trackNumber),
      ]);
    if (albumArtist == null) {
      query.where((t) => t.albumName.equals(albumName));
    } else {
      query.where(
        (t) => t.albumName.equals(albumName) & t.artist.equals(albumArtist),
      );
    }
    return query.get();
  }

  Stream<List<TracksTableData>> watchTracksByAlbum(
    String albumName,
    String? albumArtist,
  ) {
    final query = select(tracksTable)
      ..orderBy([
        (t) => OrderingTerm.asc(t.discNumber),
        (t) => OrderingTerm.asc(t.trackNumber),
      ]);
    if (albumArtist == null) {
      query.where((t) => t.albumName.equals(albumName));
    } else {
      query.where(
        (t) => t.albumName.equals(albumName) & t.artist.equals(albumArtist),
      );
    }
    return query.watch();
  }

  Stream<List<TracksTableData>> watchTracksByArtist(String artist) =>
      (select(tracksTable)
            ..where((t) => t.artist.equals(artist) & t.isIncluded.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .watch();

  Future<List<TracksTableData>> getTracksByArtist(String artist) =>
      (select(tracksTable)
            ..where((t) => t.artist.equals(artist) & t.isIncluded.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .get();

  Stream<List<QueryRow>> watchAllAlbums() => customSelect(
    'SELECT album_name, artist AS album_artist, artwork_path, release_year, COUNT(*) AS track_count '
    'FROM tracks '
    'WHERE is_included = 1 AND album_name IS NOT NULL '
    'GROUP BY album_name, artist '
    'ORDER BY album_name ASC',
    readsFrom: {tracksTable},
  ).watch();

  Stream<List<QueryRow>> watchAllDiscoveredAlbums() => customSelect(
    'SELECT album_name, artist AS album_artist, artwork_path, release_year, '
    '  COUNT(*) AS track_count, '
    '  COALESCE(SUM(CASE WHEN is_included = 1 THEN 1 ELSE 0 END), 0) AS included_count '
    'FROM tracks '
    'WHERE album_name IS NOT NULL '
    'GROUP BY album_name, artist '
    'ORDER BY album_name ASC',
    readsFrom: {tracksTable},
  ).watch();

  Stream<List<QueryRow>> watchAllArtists() => customSelect(
    'SELECT artist, COUNT(DISTINCT album_name) AS album_count '
    'FROM tracks '
    'WHERE is_included = 1 '
    'GROUP BY artist '
    'ORDER BY artist ASC',
    readsFrom: {tracksTable},
  ).watch();

  Future<List<QueryRow>> getAlbumsByArtist(String artist) => customSelect(
    'SELECT album_name, artist AS album_artist, artwork_path, release_year, COUNT(*) AS track_count '
    'FROM tracks '
    'WHERE is_included = 1 AND artist = ? AND album_name IS NOT NULL '
    'GROUP BY album_name, artist '
    'ORDER BY album_name ASC',
    variables: [Variable.withString(artist)],
    readsFrom: {tracksTable},
  ).get();

  Future<QueryRow?> getAlbumByNameAndArtist(
    String albumName,
    String? albumArtist,
  ) async {
    final sql = albumArtist == null
        ? 'SELECT album_name, artist AS album_artist, artwork_path, release_year, COUNT(*) AS track_count '
          'FROM tracks WHERE is_included = 1 AND album_name = ? '
          'GROUP BY album_name, artist'
        : 'SELECT album_name, artist AS album_artist, artwork_path, release_year, COUNT(*) AS track_count '
          'FROM tracks WHERE is_included = 1 AND album_name = ? AND artist = ? '
          'GROUP BY album_name, artist';
    final vars = albumArtist == null
        ? [Variable.withString(albumName)]
        : [Variable.withString(albumName), Variable.withString(albumArtist)];
    final rows = await customSelect(
      sql,
      variables: vars,
      readsFrom: {tracksTable},
    ).get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<QueryRow>> searchAlbums(String query) {
    final q = '%${query.toLowerCase()}%';
    return customSelect(
      'SELECT album_name, artist AS album_artist, artwork_path, release_year, COUNT(*) AS track_count '
      'FROM tracks '
      'WHERE is_included = 1 AND album_name IS NOT NULL '
      '  AND (LOWER(album_name) LIKE ? OR LOWER(artist) LIKE ?) '
      'GROUP BY album_name, artist '
      'ORDER BY album_name ASC',
      variables: [Variable.withString(q), Variable.withString(q)],
      readsFrom: {tracksTable},
    ).get();
  }

  Future<List<QueryRow>> searchArtists(String query) {
    final q = '%${query.toLowerCase()}%';
    return customSelect(
      'SELECT DISTINCT artist FROM tracks '
      'WHERE is_included = 1 AND LOWER(artist) LIKE ? '
      'ORDER BY artist ASC',
      variables: [Variable.withString(q)],
      readsFrom: {tracksTable},
    ).get();
  }

  Future<void> updateAlbumFields(
    String albumName,
    String? albumArtist, {
    String? newAlbumName,
    String? newAlbumArtist,
    String? artworkPath,
    int? releaseYear,
    String? genre,
  }) {
    final companion = TracksTableCompanion(
      albumName: newAlbumName != null ? Value(newAlbumName) : const Value.absent(),
      albumArtist: newAlbumArtist != null ? Value(newAlbumArtist) : const Value.absent(),
      artworkPath: artworkPath != null ? Value(artworkPath) : const Value.absent(),
      releaseYear: releaseYear != null ? Value(releaseYear) : const Value.absent(),
      genre: genre != null ? Value(genre) : const Value.absent(),
    );
    final query = update(tracksTable);
    if (albumArtist == null) {
      query.where((t) => t.albumName.equals(albumName) & t.albumArtist.isNull());
    } else {
      query.where(
        (t) => t.albumName.equals(albumName) & t.albumArtist.equals(albumArtist),
      );
    }
    return query.write(companion);
  }

  Future<void> updateAlbumIdentity(
    String oldAlbumName,
    String? oldAlbumArtist,
    String newName,
    String newArtist,
  ) {
    final query = update(tracksTable);
    if (oldAlbumArtist == null) {
      query.where(
        (t) => t.albumName.equals(oldAlbumName) & t.albumArtist.isNull(),
      );
    } else {
      query.where(
        (t) =>
            t.albumName.equals(oldAlbumName) &
            t.albumArtist.equals(oldAlbumArtist),
      );
    }
    return query.write(
      TracksTableCompanion(
        albumName: Value(newName),
        albumArtist: Value(newArtist),
      ),
    );
  }

  Future<List<TracksTableData>> getTracksByGenre(String genre) =>
      (select(tracksTable)
            ..where(
              (t) =>
                  t.genre.lower().equals(genre.toLowerCase()) &
                  t.isIncluded.equals(true),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .get();

  Future<List<TracksTableData>> searchTracks(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(tracksTable)
          ..where(
            (t) =>
                (t.title.lower().like(q) |
                    t.artist.lower().like(q) |
                    t.genre.lower().like(q)) &
                t.isIncluded.equals(true),
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

  // ── Mutations ──────────────────────────────────────────────────────────────

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
