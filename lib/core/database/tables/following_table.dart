import 'package:drift/drift.dart';

class FollowingTable extends Table {
  @override
  String get tableName => 'following';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get actorUrl => text().unique()();
  DateTimeColumn get followedAt => dateTime().withDefault(currentDateAndTime)();
}
