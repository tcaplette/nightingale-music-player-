import 'package:drift/drift.dart';

class NodeIdentityTable extends Table {
  @override
  String get tableName => 'node_identity';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get actorUrl => text().unique()();
  TextColumn get publicKeyPem => text()();
  TextColumn get preferredUsername => text()();
  TextColumn get displayName => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  // STUN-discovered public IP:port (e.g. "203.0.113.5:7777"); null until resolved.
  TextColumn get nodePublicAddress => text().nullable()();
  TextColumn get summary => text().nullable()();
  BlobColumn get avatarJpeg => blob().nullable()();
}
