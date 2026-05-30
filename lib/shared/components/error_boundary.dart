import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nightingale/core/crash_reporting/crash_reporter.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

// Call once at app startup (before runApp) to wire Flutter's global error display.
// In debug builds: shows the full error and stack. In release: calm message + crash report.
void setupErrorWidget() {
  ErrorWidget.builder = (details) {
    if (!kDebugMode) {
      sl<CrashReporter>().recordError(details.exception, details.stack);
      return const _ReleaseErrorWidget();
    }
    return _DebugErrorWidget(details: details);
  };
}

// Wrap any feature subtree to mark it as an error-handled region.
// The actual error display is governed by setupErrorWidget() called at startup.
// Convention: wrap every top-level feature screen in ErrorBoundaryWidget.
class ErrorBoundaryWidget extends StatelessWidget {
  const ErrorBoundaryWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _DebugErrorWidget extends StatelessWidget {
  const _DebugErrorWidget({required this.details});
  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a0000),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Flutter Rendering Error',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              details.exceptionAsString(),
              style: const TextStyle(
                color: Color(0xFFFFB3B3),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (details.stack != null)
              Text(
                details.stack.toString(),
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseErrorWidget extends StatelessWidget {
  const _ReleaseErrorWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.grey, size: 32),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Something went wrong',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
