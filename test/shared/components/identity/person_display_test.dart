import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/shared/components/identity/person_display.dart';
import 'package:nightingale/shared/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('PersonDisplay', () {
    testWidgets('shows display name by default', (tester) async {
      await tester.pumpWidget(
        _wrap(const PersonDisplay(displayName: 'Maya Patel')),
      );
      expect(find.text('Maya Patel'), findsOneWidget);
    });

    testWidgets('hides handle by default', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PersonDisplay(
            displayName: 'Maya Patel',
            handle: '@maya@example.com',
          ),
        ),
      );
      expect(find.text('Maya Patel'), findsOneWidget);
      expect(find.text('@maya@example.com'), findsNothing);
    });

    testWidgets('shows handle when showHandle is true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PersonDisplay(
            displayName: 'Maya Patel',
            handle: '@maya@example.com',
            showHandle: true,
          ),
        ),
      );
      expect(find.text('Maya Patel'), findsOneWidget);
      expect(find.text('@maya@example.com'), findsOneWidget);
    });

    testWidgets('renders initials monogram when avatarUrl is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const PersonDisplay(displayName: 'Maya Patel')),
      );
      // Monogram should show "MP"
      expect(find.text('MP'), findsOneWidget);
    });

    testWidgets('renders single initial for single-name displayName', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const PersonDisplay(displayName: 'Maya')));
      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('renders without exception when avatarUrl is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const PersonDisplay(
            displayName: 'Maya Patel',
            avatarUrl: 'https://example.com/avatar.jpg',
          ),
        ),
      );
      // CachedNetworkImage will show placeholder (monogram) in test since no network
      expect(find.byType(PersonDisplay), findsOneWidget);
    });

    testWidgets(
      'does not render handle text when showHandle is false and handle provided',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const PersonDisplay(
              displayName: 'Jordan Lee',
              handle: '@jordan@federated.example',
              showHandle: false,
            ),
          ),
        );
        expect(find.text('@jordan@federated.example'), findsNothing);
      },
    );
  });
}
