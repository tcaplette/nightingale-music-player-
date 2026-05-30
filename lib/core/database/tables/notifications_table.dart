import 'package:drift/drift.dart';

class NotificationsTable extends Table {
  @override
  String get tableName => 'notifications';

  IntColumn get rowId => integer().autoIncrement()();
  // type: new_follower | like | announce | follow_rejected
  TextColumn get type => text()();
  TextColumn get fromActorUrl => text()();
  // JSON reference to the object (track, playlist, or null)
  TextColumn get objectRef => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
