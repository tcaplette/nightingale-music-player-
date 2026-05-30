import 'package:drift/drift.dart';

class FollowersTable extends Table {
  @override
  String get tableName => 'followers';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get actorUrl => text().unique()();
  DateTimeColumn get followedAt => dateTime().withDefault(currentDateAndTime)();
}
