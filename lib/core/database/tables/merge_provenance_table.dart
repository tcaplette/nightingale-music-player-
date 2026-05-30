import 'package:drift/drift.dart';

class MergeProvenanceTable extends Table {
  @override
  String get tableName => 'merge_provenance';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get fingerprintA => text()();
  TextColumn get fingerprintB => text()();
  RealColumn get similarityScore => real()();
  DateTimeColumn get mergedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get undoneAt => dateTime().nullable()();
  TextColumn get reason => text()();
}
