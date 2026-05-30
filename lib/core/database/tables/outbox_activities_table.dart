import 'package:drift/drift.dart';

class OutboxActivitiesTable extends Table {
  @override
  String get tableName => 'outbox_activities';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get activityId => text().unique()();
  TextColumn get type => text()();
  TextColumn get targetInboxUrl => text()();
  TextColumn get payloadJson => text()();
  // status: pending | retrying | relayed | delivered | failed
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get relayReferenceId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptedAt => dateTime().nullable()();
}
