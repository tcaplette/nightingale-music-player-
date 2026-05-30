import 'package:drift/drift.dart';

class MutesTable extends Table {
  @override
  String get tableName => 'mutes';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get actorUrl => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
