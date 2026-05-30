import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/shared/components/social/activity_card.dart';
import 'package:nightingale/shared/theme/app_theme.dart';

SocialActivitiesTableData _fakeActivity({
  required String type,
  String? objectJson,
}) =>
    SocialActivitiesTableData(
      rowId: 1,
      activityId: 'https://node.example/activities/1',
      type: type,
      actorUrl: 'https://node.example/users/alice',
      objectJson: objectJson,
      rawJson: '{}',
      publishedAt: DateTime(2025, 1, 1, 12),
      storedAt: DateTime(2025, 1, 1, 12),
    );

Widget _wrap(Widget child) => MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        routes: [GoRoute(path: '/', builder: (_, __) => Scaffold(body: child))],
      ),
    );

void main() {
  group('ActivityCard', () {
    // ActivityCard uses RichText with TextSpans, so we check for
    // the ActivityCard widget rendering without error, and verify
    // semantic text content via the RichText tree.
    Finder _richTextContaining(String text) => find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains(text),
        );

    testWidgets('shows "is listening to" verb for Listen type', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ActivityCard(
            activity: _fakeActivity(
              type: 'Listen',
              objectJson:
                  '{"name":"Blue in Green","artist":"Miles Davis"}',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_richTextContaining('is listening to'), findsWidgets);
      expect(_richTextContaining('Blue in Green'), findsWidgets);
    });

    testWidgets('shows "shared" verb for Announce type', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ActivityCard(
            activity: _fakeActivity(
              type: 'Announce',
              objectJson: '{"name":"Kind of Blue","artist":"Miles Davis"}',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_richTextContaining('shared'), findsWidgets);
    });

    testWidgets('shows "saved" verb for Save type', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ActivityCard(
            activity: _fakeActivity(
              type: 'Save',
              objectJson: '{"name":"Autumn Leaves"}',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_richTextContaining('saved'), findsWidgets);
    });

    testWidgets('handles missing avatar gracefully', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ActivityCard(
            activity: _fakeActivity(type: 'Listen'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Should render without throwing — no avatar URL provided
      expect(find.byType(ActivityCard), findsOneWidget);
    });
  });
}
