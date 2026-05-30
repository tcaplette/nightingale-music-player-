import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/shared/components/network_state/buffering_widget.dart';
import 'package:nightingale/shared/components/network_state/host_offline_widget.dart';
import 'package:nightingale/shared/components/network_state/partial_library_widget.dart';
import 'package:nightingale/shared/components/network_state/stream_failed_playing_local_widget.dart';
import 'package:nightingale/shared/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('BufferingWidget', () {
    testWidgets('renders without exception and shows status label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const BufferingWidget(statusLabel: 'Connecting…')),
      );
      expect(find.text('Connecting…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('HostOfflineWidget', () {
    testWidgets('renders without exception and shows display name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const HostOfflineWidget(displayName: 'Maya')),
      );
      expect(find.textContaining('Maya'), findsOneWidget);
    });

    testWidgets('shows last seen when provided', (tester) async {
      final lastSeen = DateTime.now().subtract(const Duration(hours: 1));
      await tester.pumpWidget(
        _wrap(HostOfflineWidget(displayName: 'Maya', lastSeenAt: lastSeen)),
      );
      expect(find.textContaining('ago'), findsOneWidget);
    });

    testWidgets('omits last seen when null', (tester) async {
      await tester.pumpWidget(
        _wrap(const HostOfflineWidget(displayName: 'Jordan')),
      );
      expect(find.textContaining('Last seen'), findsNothing);
    });
  });

  group('StreamFailedPlayingLocalWidget', () {
    testWidgets('renders without exception and shows default label', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const StreamFailedPlayingLocalWidget()));
      expect(find.text('Playing cached copy'), findsOneWidget);
    });

    testWidgets('shows custom status label', (tester) async {
      await tester.pumpWidget(
        _wrap(const StreamFailedPlayingLocalWidget(statusLabel: 'Local cache')),
      );
      expect(find.text('Local cache'), findsOneWidget);
    });
  });

  group('PartialLibraryWidget', () {
    testWidgets('renders without exception and shows display name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const PartialLibraryWidget(displayName: 'Alex')),
      );
      expect(find.textContaining('Alex'), findsOneWidget);
    });

    testWidgets('shows custom status label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PartialLibraryWidget(
            displayName: 'Alex',
            statusLabel: '12 of 200',
          ),
        ),
      );
      expect(find.textContaining('12 of 200'), findsOneWidget);
    });
  });
}
