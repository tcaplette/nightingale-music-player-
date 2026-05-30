import 'package:drift/drift.dart';

class ArtistsTable extends Table {
  @override
  String get tableName => 'artists';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}
