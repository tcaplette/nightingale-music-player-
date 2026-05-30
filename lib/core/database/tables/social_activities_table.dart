import 'package:drift/drift.dart';

class SocialActivitiesTable extends Table {
  @override
  String get tableName => 'social_activities';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get activityId => text().unique()();
  // type: Listen | Announce | Like | Save
  TextColumn get type => text()();
  TextColumn get actorUrl => text()();
  TextColumn get objectJson => text().nullable()();
  TextColumn get rawJson => text()();
  DateTimeColumn get publishedAt => dateTime()();
  DateTimeColumn get storedAt => dateTime().withDefault(currentDateAndTime)();
}
