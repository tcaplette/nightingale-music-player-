import 'package:drift/drift.dart';
import 'package:nightingale/core/database/tables/albums_table.dart';

class TracksTable extends Table {
  @override
  String get tableName => 'tracks';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text().unique()();
  TextColumn get title => text()();
  TextColumn get artist => text().withDefault(const Constant('Unknown Artist'))();
  IntColumn get albumId => integer().nullable().references(AlbumsTable, #id)();
  TextColumn get albumArtist => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();
  TextColumn get genre => text().nullable()();
  IntColumn get releaseYear => integer().nullable()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  TextColumn get artworkPath => text().nullable()();
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();
}
