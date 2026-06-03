import 'package:drift/drift.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/database/tables/albums_table.dart';
import 'package:nightingale/core/database/tables/tracks_table.dart';

part 'album_dao.g.dart';

@DriftAccessor(tables: [AlbumsTable, TracksTable])
class AlbumDao extends DatabaseAccessor<AppDatabase> with _$AlbumDaoMixin {
  AlbumDao(super.db);

  // ── Library queries (albums with at least one included track) ──────────────

  Future<List<AlbumsTableData>> getAllAlbums() {
    return customSelect(
      'SELECT * FROM albums WHERE id IN ('
      '  SELECT DISTINCT album_id FROM tracks'
      '  WHERE is_included = 1 AND album_id IS NOT NULL'
      ') ORDER BY name ASC',
      readsFrom: {albumsTable, tracksTable},
    ).get().then((rows) => rows.map(_albumFromRow).toList());
  }

  Stream<List<AlbumsTableData>> watchAllAlbums() {
    return customSelect(
      'SELECT * FROM albums WHERE id IN ('
      '  SELECT DISTINCT album_id FROM tracks'
      '  WHERE is_included = 1 AND album_id IS NOT NULL'
      ') ORDER BY name ASC',
      readsFrom: {albumsTable, tracksTable},
    ).watch().map((rows) => rows.map(_albumFromRow).toList());
  }

  // ── Discovery queries (all albums with per-album inclusion count) ───────────

  /// Returns all albums regardless of inclusion, with a count of how many
  /// of their tracks are currently included. Used by the albums selection sheet.
  Stream<List<(AlbumsTableData, int)>> watchAllDiscoveredAlbums() {
    return customSelect(
      'SELECT a.id, a.name, a.artist, a.artwork_path, a.release_year, a.track_count, '
      'COALESCE(SUM(CASE WHEN t.is_included = 1 THEN 1 ELSE 0 END), 0) AS included_count '
      'FROM albums a '
      'LEFT JOIN tracks t ON t.album_id = a.id '
      'GROUP BY a.id '
      'ORDER BY a.name ASC',
      readsFrom: {albumsTable, tracksTable},
    ).watch().map(
      (rows) => rows
          .map((row) => (_albumFromRow(row), row.read<int>('included_count')))
          .toList(),
    );
  }

  // ── Artist / search queries ────────────────────────────────────────────────

  Future<List<AlbumsTableData>> getAlbumsByArtist(String artist) {
    return customSelect(
      'SELECT * FROM albums WHERE artist = ? AND id IN ('
      '  SELECT DISTINCT album_id FROM tracks'
      '  WHERE is_included = 1 AND album_id IS NOT NULL'
      ') ORDER BY name ASC',
      variables: [Variable.withString(artist)],
      readsFrom: {albumsTable, tracksTable},
    ).get().then((rows) => rows.map(_albumFromRow).toList());
  }

  Future<List<AlbumsTableData>> searchAlbums(String query) {
    final q = '%${query.toLowerCase()}%';
    return customSelect(
      'SELECT * FROM albums WHERE (LOWER(name) LIKE ? OR LOWER(artist) LIKE ?) AND id IN ('
      '  SELECT DISTINCT album_id FROM tracks'
      '  WHERE is_included = 1 AND album_id IS NOT NULL'
      ') ORDER BY name ASC',
      variables: [Variable.withString(q), Variable.withString(q)],
      readsFrom: {albumsTable, tracksTable},
    ).get().then((rows) => rows.map(_albumFromRow).toList());
  }

  Future<AlbumsTableData?> getAlbumById(int id) =>
      (select(albumsTable)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<AlbumsTableData?> getAlbumByNameAndArtist(
    String name,
    String artist,
  ) =>
      (select(albumsTable)
            ..where((a) => a.name.equals(name) & a.artist.equals(artist)))
          .getSingleOrNull();

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<int> upsertAlbum(AlbumsTableCompanion album) =>
      into(albumsTable).insertOnConflictUpdate(album);

  Future<void> updateTrackCount(int albumId, int count) =>
      (update(albumsTable)..where((a) => a.id.equals(albumId)))
          .write(AlbumsTableCompanion(trackCount: Value(count)));

  Future<void> updateNameAndArtist(
    int albumId, {
    required String name,
    required String artist,
  }) =>
      (update(albumsTable)..where((a) => a.id.equals(albumId))).write(
        AlbumsTableCompanion(
          name: Value(name),
          artist: Value(artist),
        ),
      );

  Future<void> updateMetadata(
    int albumId, {
    String? artworkPath,
    int? releaseYear,
  }) =>
      (update(albumsTable)..where((a) => a.id.equals(albumId))).write(
        AlbumsTableCompanion(
          artworkPath:
              artworkPath != null ? Value(artworkPath) : const Value.absent(),
          releaseYear:
              releaseYear != null ? Value(releaseYear) : const Value.absent(),
        ),
      );

  Future<void> updateAfterFetch(
    int albumId, {
    required String name,
    required String artist,
    String? artworkPath,
    int? releaseYear,
  }) =>
      (update(albumsTable)..where((a) => a.id.equals(albumId))).write(
        AlbumsTableCompanion(
          name: Value(name),
          artist: Value(artist),
          artworkPath:
              artworkPath != null ? Value(artworkPath) : const Value.absent(),
          releaseYear:
              releaseYear != null ? Value(releaseYear) : const Value.absent(),
        ),
      );

  Future<int> deleteAlbumById(int id) =>
      (delete(albumsTable)..where((a) => a.id.equals(id))).go();

  // ── Private helpers ────────────────────────────────────────────────────────

  AlbumsTableData _albumFromRow(QueryRow row) {
    return AlbumsTableData(
      id: row.read<int>('id'),
      name: row.read<String>('name'),
      artist: row.read<String>('artist'),
      artworkPath: row.readNullable<String>('artwork_path'),
      releaseYear: row.readNullable<int>('release_year'),
      trackCount: row.read<int>('track_count'),
    );
  }
}
