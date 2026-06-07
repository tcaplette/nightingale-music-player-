import 'package:drift/drift.dart';

class FollowsTable extends Table {
  @override
  String get tableName => 'follows';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get localActorId => text()();
  TextColumn get remoteActorUrl => text()();
  // state: accepted | pending | pending_delivery
  TextColumn get state => text().withDefault(const Constant('accepted'))();
  TextColumn get mastodonHandle => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
