import 'package:drift/drift.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/database/tables/albums_table.dart';

part 'album_dao.g.dart';

@DriftAccessor(tables: [AlbumsTable])
class AlbumDao extends DatabaseAccessor<AppDatabase> with _$AlbumDaoMixin {
  AlbumDao(super.db);

  Future<List<AlbumsTableData>> getAllAlbums() =>
      (select(albumsTable)..orderBy([(a) => OrderingTerm.asc(a.name)])).get();

  Stream<List<AlbumsTableData>> watchAllAlbums() =>
      (select(albumsTable)..orderBy([(a) => OrderingTerm.asc(a.name)])).watch();

  Future<List<AlbumsTableData>> getAlbumsByArtist(String artist) =>
      (select(albumsTable)
            ..where((a) => a.artist.equals(artist))
            ..orderBy([(a) => OrderingTerm.asc(a.name)]))
          .get();

  Future<List<AlbumsTableData>> searchAlbums(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(albumsTable)
          ..where(
            (a) => a.name.lower().like(q) | a.artist.lower().like(q),
          )
          ..orderBy([(a) => OrderingTerm.asc(a.name)]))
        .get();
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

  /// Writes all fields resolved during a batch fetch in one shot.
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
}
