import 'package:drift/drift.dart';

class ChunksTable extends Table {
  @override
  String get tableName => 'chunks';

  BlobColumn get hash => blob()();
  BlobColumn get data => blob()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get lastAccessed =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {hash};
}
