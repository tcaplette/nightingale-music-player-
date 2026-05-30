import 'package:drift/drift.dart';

class TasteScoresTable extends Table {
  @override
  String get tableName => 'taste_scores';

  // AES-256-GCM encrypted fingerprint. Equality queries are not possible
  // against this column — all scoring is done in memory after decryption.
  TextColumn get trackFingerprint => text()();
  RealColumn get score => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {trackFingerprint};
}
