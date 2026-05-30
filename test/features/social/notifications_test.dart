import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/social/providers/notifications_notifier.dart';
import 'package:nightingale/features/social/screens/notifications_screen.dart';
import 'package:nightingale/shared/theme/app_theme.dart';

AppDatabase _testDb() => AppDatabase(NativeDatabase.memory());

// Stub that overrides load() to avoid DB access.
class _StubNotifNotifier extends NotificationsNotifier {
  final NotificationsState _fixed;

  _StubNotifNotifier(this._fixed, AppDatabase db) : super(db);

  @override
  Future<void> load() async => state = _fixed;

  @override
  Future<void> markAllRead() async {}
}

Widget _wrap(Widget child, NotificationsState notifState) => ProviderScope(
      overrides: [
        notificationsProvider.overrideWith(
          (ref) => _StubNotifNotifier(notifState, _testDb()),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => Scaffold(body: child)),
          ],
        ),
      ),
    );

NotificationsTableData _fakeNotif(int i) => NotificationsTableData(
      rowId: i,
      type: 'like',
      fromActorUrl: 'https://node$i.example/users/u',
      objectRef: 'https://node.example/tracks/1',
      isRead: false,
      createdAt: DateTime(2025, 1, 1),
    );

void main() {
  group('NotificationsScreen', () {
    testWidgets('shows empty state when no notifications', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const NotificationsScreen(),
          const NotificationsState(groups: [], unreadCount: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No notifications yet'), findsOneWidget);
    });

    testWidgets('"Mark all read" visible when unreadCount > 0', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const NotificationsScreen(),
          const NotificationsState(groups: [], unreadCount: 3),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mark all read'), findsOneWidget);
    });
  });

  group('GroupedNotification.isGrouped', () {
    test('returns true when senders >= 3', () {
      final senders = List.generate(3, _fakeNotif);
      final group = GroupedNotification(
        type: 'like',
        objectRef: null,
        senders: senders,
        latest: senders.first,
      );
      expect(group.isGrouped, isTrue);
    });

    test('returns false when senders < 3', () {
      final senders = List.generate(2, _fakeNotif);
      final group = GroupedNotification(
        type: 'like',
        objectRef: null,
        senders: senders,
        latest: senders.first,
      );
      expect(group.isGrouped, isFalse);
    });
  });
}
