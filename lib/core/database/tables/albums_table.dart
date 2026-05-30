import 'package:drift/drift.dart';

class AlbumsTable extends Table {
  @override
  String get tableName => 'albums';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get artist => text().withDefault(const Constant('Unknown Artist'))();
  TextColumn get artworkPath => text().nullable()();
  IntColumn get releaseYear => integer().nullable()();
  IntColumn get trackCount => integer().withDefault(const Constant(0))();
}
