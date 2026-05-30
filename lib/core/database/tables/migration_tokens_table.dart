import 'package:drift/drift.dart';

class MigrationTokensTable extends Table {
  @override
  String get tableName => 'migration_tokens';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get tokenHash => text().unique()();
  TextColumn get newActorUrl => text().nullable()();
  DateTimeColumn get usedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
