import 'package:drift/drift.dart';

class RemoteLibrariesTable extends Table {
  @override
  String get tableName => 'remote_libraries';

  TextColumn get actorUrl => text()();
  TextColumn get collectionJson => text()();
  DateTimeColumn get fetchedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get etag => text().nullable()();

  @override
  Set<Column> get primaryKey => {actorUrl};
}
