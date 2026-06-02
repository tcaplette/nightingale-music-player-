import 'package:drift/drift.dart';

class ChunkManifestsTable extends Table {
  @override
  String get tableName => 'chunk_manifests';

  IntColumn get trackId => integer()();
  TextColumn get sourceActorUrl => text()();
  TextColumn get chunkHashes => text()(); // JSON array of hex-encoded SHA-256 hashes
  IntColumn get totalSizeBytes => integer()();
  DateTimeColumn get fetchedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {trackId, sourceActorUrl};
}
