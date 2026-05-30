import 'package:drift/drift.dart';

class AudioCacheTable extends Table {
  @override
  String get tableName => 'audio_cache';

  TextColumn get trackId => text()();
  TextColumn get sourceActorUrl => text()();
  TextColumn get localPath => text()();
  DateTimeColumn get fetchedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAccessed => dateTime().withDefault(currentDateAndTime)();
  IntColumn get sizeBytes => integer()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {trackId, sourceActorUrl};
}
