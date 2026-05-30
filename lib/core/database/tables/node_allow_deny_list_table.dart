import 'package:drift/drift.dart';

class NodeAllowDenyListTable extends Table {
  @override
  String get tableName => 'node_allow_deny_list';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get domain => text().unique()();
  // policy: allow | deny
  TextColumn get policy => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
