import 'package:drift/drift.dart';

class SignalEventsTable extends Table {
  @override
  String get tableName => 'signal_events';

  IntColumn get id => integer().autoIncrement()();
  // AES-256-GCM encrypted, base64-encoded. See EncryptedSignalStore.
  TextColumn get trackFingerprint => text()();
  // Values: play | skip | save | like | playlist_add | network_listen | network_like
  TextColumn get eventType => text()();
  // AES-256-GCM encrypted when non-null.
  TextColumn get sourceActorId => text().nullable()();
  IntColumn get timestampUtcMs => integer()();
  RealColumn get weight => real()();
}
