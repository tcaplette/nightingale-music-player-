import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/features/onboarding/screens/onboarding_shell.dart';
import 'package:nightingale/shared/theme/app_theme.dart';

void main() {
  testWidgets('OnboardingShell renders the welcome screen on first load',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingShell(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('nightingale'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('Tapping Get started advances to sign-in step', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in with Mastodon'), findsWidgets);
  });
}
