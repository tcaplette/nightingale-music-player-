import 'package:drift/drift.dart';

class DefederatedNodesTable extends Table {
  @override
  String get tableName => 'defederated_nodes';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get domain => text().unique()();
  DateTimeColumn get blockedAt => dateTime().withDefault(currentDateAndTime)();
}
