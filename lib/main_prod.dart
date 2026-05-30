import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:nightingale/core/config/env_config.dart';
import 'package:nightingale/core/crash_reporting/crash_reporter.dart';
import 'package:nightingale/core/crash_reporting/sentry_crash_reporter.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/shared/components/error_boundary.dart';
import 'package:nightingale/app.dart';

// Build-time SENTRY_DSN supplied via --dart-define=SENTRY_DSN=...
const _sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 50;

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.nightingale.audio',
    androidNotificationChannelName: 'Nightingale',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );
  AppConfig.initialize(Environment.prod);
  await setupServiceLocator();

  // Phase 7: wire production error reporting (non-PII only, allowlist-filtered).
  // Register SentryCrashReporter if DSN is provided; fall back silently.
  CrashReporter? reporter;
  if (_sentryDsn.isNotEmpty) {
    await SentryCrashReporter.initialize(_sentryDsn);
    reporter = SentryCrashReporter(dsn: _sentryDsn);
  }
  final effectiveReporter = reporter ?? const NullCrashReporter();

  // Wire Flutter and platform error handlers to the crash reporter.
  FlutterError.onError = (details) {
    effectiveReporter.recordError(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    effectiveReporter.recordError(error, stack);
    return true;
  };

  setupErrorWidget();
  runApp(const NightingaleApp());
}
