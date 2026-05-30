import 'package:drift/drift.dart';

class PlaylistsTable extends Table {
  @override
  String get tableName => 'playlists';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get title => text()();
  // visibility: public | followers | private
  TextColumn get visibility => text().withDefault(const Constant('private'))();
  TextColumn get collectionUrl => text().nullable()();
  // JSON-encoded list of track IDs
  TextColumn get trackIdsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
