import 'package:drift/drift.dart';

class BlocksTable extends Table {
  @override
  String get tableName => 'blocks';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get actorUrl => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
