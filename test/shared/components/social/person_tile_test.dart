import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/shared/components/social/person_tile.dart';
import 'package:nightingale/shared/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );

void main() {
  group('PersonTile', () {
    testWidgets('renders display name', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PersonTile(displayName: 'Maya Patel'),
        ),
      );
      expect(find.text('Maya Patel'), findsOneWidget);
    });

    testWidgets('does not render raw handle in primary layout', (tester) async {
      // PersonTile has no handle parameter — this test verifies
      // by design that the component accepts no handle argument,
      // enforcing the person-first contract at the type level.
      await tester.pumpWidget(
        _wrap(
          const PersonTile(
            displayName: 'Maya Patel',
            secondaryLabel: 'Listening to jazz',
          ),
        ),
      );
      expect(find.text('Maya Patel'), findsOneWidget);
      expect(find.text('Listening to jazz'), findsOneWidget);
      // Verify no @ symbol appears at the top level
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrap(
          PersonTile(
            displayName: 'Jordan Lee',
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(PersonTile));
      expect(tapped, isTrue);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PersonTile(
            displayName: 'Alex',
            trailing: Icon(Icons.chevron_right, key: Key('chevron')),
          ),
        ),
      );
      expect(find.byKey(const Key('chevron')), findsOneWidget);
    });
  });
}
