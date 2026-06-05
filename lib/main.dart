import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:nightingale/core/config/env_config.dart';
import 'package:nightingale/core/crash_reporting/crash_log_service.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/shared/components/error_boundary.dart';
import 'package:nightingale/app.dart';

void _logCrash(String label, Object error, StackTrace? stack) {
  // Always print so it appears in `flutter run` console regardless of log level.
  // ignore: avoid_print
  print('\n══════════ $label ══════════\n$error\n${stack ?? ''}\n');
  developer.log(
    '$label\n$error',
    name: 'nightingale.crash',
    error: error,
    stackTrace: stack,
    level: 1200, // SHOUT
  );
  // Persist to disk — survives process death so we can read it on next launch.
  CrashLogService.write(label, error, stack);
}

void main() async {
  developer.Timeline.startSync('startup');
  developer.log('MAIN: start', name: 'nightingale.main');

  developer.Timeline.startSync('binding_init');
  WidgetsFlutterBinding.ensureInitialized();
  // Cap in-memory image cache to 50 images; disk cache capped via
  // cached_network_image configuration in the widget layer.
  PaintingBinding.instance.imageCache.maximumSize = 50;
  developer.Timeline.finishSync();
  developer.log('MAIN: WidgetsFlutterBinding done', name: 'nightingale.main');

  // Dump any crash log written by the previous session before we do anything
  // else, so the output appears at the very top of the new session's console.
  await CrashLogService.reportAndClear();

  // Attach an isolate-level error listener. This fires for errors that escape
  // all zone and framework hooks and would otherwise kill the isolate silently.
  // The listener writes to disk synchronously before the process can die.
  CrashLogService.attachIsolateListener();

  // ── Global crash hooks ────────────────────────────────────────────────────

  // Flutter framework errors (widget build failures, layout overflows that
  // become fatal, assertion errors thrown inside the framework, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    _logCrash('FlutterError', details.exceptionAsString(), details.stack);
    // In debug mode keep the default red-screen behaviour on top of our log.
    if (kDebugMode) FlutterError.presentError(details);
  };

  // Uncaught errors on the platform / root isolate (async gaps that escape the
  // zone, native-to-Dart callbacks, etc.)  Available since Flutter 3.3.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _logCrash('PlatformDispatcher.onError', error, stack);
    return true; // returning true means we've handled it; false would re-throw
  };

  // ─────────────────────────────────────────────────────────────────────────

  developer.Timeline.startSync('just_audio_background_init');
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.nightingale.audio',
    androidNotificationChannelName: 'Nightingale',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );
  developer.Timeline.finishSync();
  developer.log('MAIN: JustAudioBackground.init done', name: 'nightingale.main');

  AppConfig.initialize(Environment.dev);
  developer.log('MAIN: AppConfig initialized', name: 'nightingale.main');

  developer.Timeline.startSync('service_locator_init');
  await setupServiceLocator();
  developer.Timeline.finishSync();
  developer.log('MAIN: setupServiceLocator done', name: 'nightingale.main');

  setupErrorWidget();
  developer.log('MAIN: setupErrorWidget done', name: 'nightingale.main');

  developer.Timeline.startSync('run_app');
  // runZonedGuarded catches any unhandled error that lands in the current zone
  // but was not caught by either of the hooks above (e.g. unawaited futures
  // that throw inside a zone-unaware callback).
  runZonedGuarded(
    () {
      runApp(const NightingaleApp());
      developer.Timeline.finishSync(); // run_app
      developer.Timeline.finishSync(); // startup
      developer.log('MAIN: runApp called', name: 'nightingale.main');
    },
    (Object error, StackTrace stack) {
      _logCrash('runZonedGuarded', error, stack);
    },
  );
}
