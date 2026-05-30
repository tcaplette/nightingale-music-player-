import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/shared/components/empty_state_widget.dart';
import 'package:nightingale/shared/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );

void main() {
  group('EmptyStateWidget', () {
    testWidgets('renders headline and icon without exception', (tester) async {
      await tester.pumpWidget(
        _wrap(const EmptyStateWidget(
          icon: Icons.music_note_outlined,
          headline: 'No music yet',
        )),
      );
      expect(find.text('No music yet'), findsOneWidget);
      expect(find.byIcon(Icons.music_note_outlined), findsOneWidget);
    });

    testWidgets('shows subhead when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(const EmptyStateWidget(
          icon: Icons.people_outline,
          headline: 'Nothing here yet',
          subhead: 'Follow people to see their music.',
        )),
      );
      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.text('Follow people to see their music.'), findsOneWidget);
    });

    testWidgets('does not throw when subhead is absent', (tester) async {
      await tester.pumpWidget(
        _wrap(const EmptyStateWidget(
          icon: Icons.search,
          headline: 'No results',
        )),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('No results'), findsOneWidget);
    });
  });
}
