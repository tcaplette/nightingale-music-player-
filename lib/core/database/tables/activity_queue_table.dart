import 'package:drift/drift.dart';

/// Durable queue for outgoing ActivityPub activities when the device is offline.
/// Flushed FIFO on reconnect by OfflineModeCoordinator.
class ActivityQueueTable extends Table {
  @override
  String get tableName => 'activity_queue';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get activityJson => text()();
  TextColumn get activityType => text()();
  TextColumn get targetActorUrl => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  /// Values: 'pending' | 'delivering' | 'dead'
  TextColumn get status => text().withDefault(const Constant('pending'))();
}
