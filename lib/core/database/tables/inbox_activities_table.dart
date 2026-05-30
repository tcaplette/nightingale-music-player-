import 'package:drift/drift.dart';

class InboxActivitiesTable extends Table {
  @override
  String get tableName => 'inbox_activities';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get activityId => text().unique()();
  TextColumn get type => text()();
  TextColumn get actorUrl => text()();
  TextColumn get objectJson => text().nullable()();
  TextColumn get rawJson => text()();
  DateTimeColumn get receivedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get processed => boolean().withDefault(const Constant(false))();
}
