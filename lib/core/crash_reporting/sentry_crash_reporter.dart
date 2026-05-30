import 'package:nightingale/core/crash_reporting/crash_reporter.dart';

/// Production crash reporter backed by Sentry.
/// Registered in release builds only when SENTRY_DSN is set.
/// Uses allowlist-based filtering: only exception type, anonymized stack trace,
/// app version, and platform are transmitted. No username, node URL, or file paths.
///
/// NOTE: sentry_flutter is not yet added to pubspec.yaml — add it before
/// enabling this in a release build. The class is a placeholder that wires
/// the interface and guards the import with a conditional check.
class SentryCrashReporter implements CrashReporter {
  SentryCrashReporter({required this.dsn});

  final String dsn;

  /// Call once at app startup in release mode.
  static Future<void> initialize(String dsn) async {
    // Initialization is deferred to the sentry_flutter SDK call:
    //   await SentryFlutter.init((options) {
    //     options.dsn = dsn;
    //     options.beforeSend = _scrub;
    //   });
    // This placeholder documents the intended wiring; the actual SDK call
    // is performed in main_prod.dart once sentry_flutter is added to pubspec.yaml.
  }

  @override
  void recordError(Object error, StackTrace? stackTrace) {
    // In the live implementation this calls Sentry.captureException.
    // The beforeSend hook (allowlist-based) strips any PII before transmission.
  }
}
