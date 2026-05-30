import 'package:drift/drift.dart';

class FollowRequestsTable extends Table {
  @override
  String get tableName => 'follow_requests';

  IntColumn get rowId => integer().autoIncrement()();
  // direction: incoming | outgoing
  TextColumn get direction => text()();
  TextColumn get actorUrl => text()();
  // state: pending | pending_review | accepted | rejected | cancelled | pending_delivery
  TextColumn get state => text().withDefault(const Constant('pending'))();
  TextColumn get activityId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
