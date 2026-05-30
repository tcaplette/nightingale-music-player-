import 'package:drift/drift.dart';
import 'package:nightingale/core/database/app_database.dart';

enum ListPolicy { allow, deny }

class ModerationRepository {
  ModerationRepository({required this.db});
  final AppDatabase db;

  Future<bool> isDefederated(String domain) async {
    final row = await (db.select(db.defederatedNodesTable)
          ..where((t) => t.domain.equals(domain)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> defederate(String domain) async {
    await db.into(db.defederatedNodesTable).insertOnConflictUpdate(
          DefederatedNodesTableCompanion.insert(domain: domain),
        );
  }

  Future<void> removeDefederation(String domain) async {
    await (db.delete(db.defederatedNodesTable)
          ..where((t) => t.domain.equals(domain)))
        .go();
  }

  Future<List<DefederatedNodesTableData>> getDefederatedNodes() =>
      db.select(db.defederatedNodesTable).get();

  Future<List<NodeAllowDenyListTableData>> getAllowList() async =>
      (db.select(db.nodeAllowDenyListTable)
            ..where((t) => t.policy.equals('allow')))
          .get();

  Future<List<NodeAllowDenyListTableData>> getDenyList() async =>
      (db.select(db.nodeAllowDenyListTable)
            ..where((t) => t.policy.equals('deny')))
          .get();

  Future<void> addToList(String domain, ListPolicy policy) async {
    await db.into(db.nodeAllowDenyListTable).insertOnConflictUpdate(
          NodeAllowDenyListTableCompanion.insert(
            domain: domain,
            policy: policy.name,
          ),
        );
  }

  Future<void> removeFromList(String domain) async {
    await (db.delete(db.nodeAllowDenyListTable)
          ..where((t) => t.domain.equals(domain)))
        .go();
  }
}
