import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/settings/data/settings_repository.dart';

class GroupedNotification {
  const GroupedNotification({
    required this.type,
    required this.objectRef,
    required this.senders,
    required this.latest,
  });

  final String type;
  final String? objectRef;
  final List<NotificationsTableData> senders;
  final NotificationsTableData latest;

  bool get isGrouped => senders.length >= 3;
}

class NotificationsState {
  const NotificationsState({
    this.groups = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  final List<GroupedNotification> groups;
  final int unreadCount;
  final bool isLoading;
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._db) : super(const NotificationsState()) {
    load();
  }

  NotificationsNotifier.stub() : _db = null, super(const NotificationsState());

  final AppDatabase? _db;

  Future<void> load() async {
    final db = _db;
    if (!mounted || db == null) return;
    state = NotificationsState(
      groups: state.groups,
      unreadCount: state.unreadCount,
      isLoading: true,
    );

    final repo = sl<SettingsRepository>();
    final notifyFollowers = await repo.isNotifyNewFollowersEnabled();
    final notifyActivity = await repo.isNotifyActivityFeedEnabled();
    final autoClear = await repo.getNotificationAutoClear();

    // Auto-clear old read notifications if threshold is set
    final clearThreshold = autoClear.duration;
    if (clearThreshold != null) {
      final cutoff = DateTime.now().subtract(clearThreshold);
      await (db.delete(db.notificationsTable)
            ..where((t) =>
                t.isRead &
                t.createdAt.isSmallerThanValue(cutoff)))
          .go();
    }

    var query = db.select(db.notificationsTable)
      ..orderBy([
        (t) => OrderingTerm(
              expression: t.createdAt,
              mode: OrderingMode.desc,
            ),
      ]);

    final all = await query.get();

    if (!mounted) return;

    // Filter by notification preferences
    final filtered = all.where((n) {
      if (n.type == 'new_follower' && !notifyFollowers) return false;
      if (n.type != 'new_follower' && !notifyActivity) return false;
      return true;
    }).toList();

    // Group by type + objectRef; collapse to single entry when count >= 3
    final Map<String, List<NotificationsTableData>> grouped = {};
    for (final n in filtered) {
      final key = '${n.type}:${n.objectRef}';
      grouped.putIfAbsent(key, () => []).add(n);
    }

    final groups = grouped.entries
        .map((entry) {
          final items = entry.value;
          return GroupedNotification(
            type: items.first.type,
            objectRef: items.first.objectRef,
            senders: items,
            latest: items.first,
          );
        })
        .toList()
      ..sort(
        (a, b) => b.latest.createdAt.compareTo(a.latest.createdAt),
      );

    final unread = filtered.where((n) => !n.isRead).length;

    if (!mounted) return;
    state = NotificationsState(
      groups: groups,
      unreadCount: unread,
      isLoading: false,
    );
  }

  Future<void> markAllRead() async {
    final db = _db;
    if (db == null) return;
    await (db.update(db.notificationsTable)).write(
      const NotificationsTableCompanion(isRead: Value(true)),
    );
    await load();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
  (ref) => NotificationsNotifier(sl<AppDatabase>()),
);
