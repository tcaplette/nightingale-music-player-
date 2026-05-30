class ScanFileError {
  const ScanFileError({required this.filePath, required this.reason});
  final String filePath;
  final String reason;
}

class ScanResult {
  const ScanResult({
    required this.totalFound,
    required this.parsed,
    required this.rejected,
    required this.errors,
    required this.durationMs,
    required this.completedAt,
  });

  final int totalFound;
  final int parsed;
  final int rejected;
  final List<ScanFileError> errors;
  final int durationMs;
  final DateTime completedAt;

  int get skipped => totalFound - parsed - rejected;
}
