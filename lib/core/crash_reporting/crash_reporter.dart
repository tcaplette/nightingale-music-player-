abstract interface class CrashReporter {
  void recordError(Object error, StackTrace? stackTrace);
}

class NullCrashReporter implements CrashReporter {
  const NullCrashReporter();

  @override
  void recordError(Object error, StackTrace? stackTrace) {}
}
