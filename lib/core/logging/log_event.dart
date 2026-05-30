enum LogLevel { verbose, debug, info, warning, error, fatal }

class LogEvent {
  const LogEvent({
    required this.level,
    required this.tag,
    required this.message,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  final LogLevel level;
  final String tag;
  final String message;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;
}
