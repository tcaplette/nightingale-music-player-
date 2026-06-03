import 'package:drift/drift.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/database/tables/artists_table.dart';

part 'artist_dao.g.dart';

@DriftAccessor(tables: [ArtistsTable])
class ArtistDao extends DatabaseAccessor<AppDatabase> with _$ArtistDaoMixin {
  ArtistDao(super.db);

  Future<List<ArtistsTableData>> getAllArtists() =>
      (select(artistsTable)..orderBy([(a) => OrderingTerm.asc(a.name)])).get();

  Stream<List<ArtistsTableData>> watchAllArtists() =>
      (select(artistsTable)..orderBy([(a) => OrderingTerm.asc(a.name)])).watch();

  Future<List<ArtistsTableData>> searchArtists(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(artistsTable)
          ..where((a) => a.name.lower().like(q))
          ..orderBy([(a) => OrderingTerm.asc(a.name)]))
        .get();
  }

  Future<ArtistsTableData?> getArtistByName(String name) =>
      (select(artistsTable)..where((a) => a.name.equals(name)))
          .getSingleOrNull();

  Future<ArtistsTableData?> getArtistById(int id) =>
      (select(artistsTable)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<int> upsertArtist(ArtistsTableCompanion artist) =>
      into(artistsTable).insertOnConflictUpdate(artist);

  Future<int> deleteArtistByName(String name) =>
      (delete(artistsTable)..where((a) => a.name.equals(name))).go();
}
