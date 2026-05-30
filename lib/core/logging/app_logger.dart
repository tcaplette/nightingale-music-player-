import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:nightingale/core/crash_reporting/crash_reporter.dart';
import 'package:nightingale/core/logging/log_event.dart';

class AppLogger {
  AppLogger._();

  static CrashReporter? _crashReporter;

  static StreamController<LogEvent>? _controller;

  static Stream<LogEvent> get logStream {
    assert(kDebugMode, 'logStream is only available in debug builds');
    _controller ??= StreamController<LogEvent>.broadcast();
    return _controller!.stream;
  }

  static void initialize(CrashReporter crashReporter) {
    _crashReporter = crashReporter;
    if (kDebugMode) {
      _controller = StreamController<LogEvent>.broadcast();
    }
  }

  static void verbose(String message, {String tag = 'app'}) {
    _log(LogLevel.verbose, tag, message);
  }

  static void debug(String message, {String tag = 'app'}) {
    _log(LogLevel.debug, tag, message);
  }

  static void info(String message, {String tag = 'app'}) {
    _log(LogLevel.info, tag, message);
  }

  static void warning(String message, {String tag = 'app'}) {
    _log(LogLevel.warning, tag, message);
  }

  static void error(
    String message, {
    String tag = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);
    _crashReporter?.recordError(error ?? message, stackTrace);
  }

  static void fatal(
    String message, {
    String tag = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.fatal, tag, message, error: error, stackTrace: stackTrace);
    _crashReporter?.recordError(error ?? message, stackTrace);
  }

  static void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final event = LogEvent(
      level: level,
      tag: tag,
      message: message,
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );

    if (kDebugMode) {
      _controller?.add(event);
      developer.log(
        message,
        name: tag,
        level: _developerLevel(level),
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static int _developerLevel(LogLevel level) => switch (level) {
    LogLevel.verbose => 300,
    LogLevel.debug => 500,
    LogLevel.info => 800,
    LogLevel.warning => 900,
    LogLevel.error => 1000,
    LogLevel.fatal => 1200,
  };
}
