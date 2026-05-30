import 'package:drift/drift.dart';

class FingerprintsTable extends Table {
  @override
  String get tableName => 'fingerprints';

  IntColumn get trackId => integer()();
  TextColumn get chromaprintHash => text()();
  IntColumn get durationMs => integer()();
  DateTimeColumn get computedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {trackId};
}
