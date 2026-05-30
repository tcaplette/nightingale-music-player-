import 'package:drift/drift.dart';

class ListenActivitiesTable extends Table {
  @override
  String get tableName => 'listen_activities';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get actorUrl => text()();
  TextColumn get trackId => text()();
  TextColumn get trackTitle => text()();
  TextColumn get trackArtist => text()();
  DateTimeColumn get listenedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
}
