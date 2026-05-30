import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/library/models/scan_result.dart';

class LibraryScanLogState {
  const LibraryScanLogState({
    required this.isScanning,
    this.lastResult,
    this.startedAt,
  });

  final bool isScanning;
  final ScanResult? lastResult;
  final DateTime? startedAt;

  static const idle = LibraryScanLogState(isScanning: false);
}

// Gate at compile time — registered only in debug builds.
final libraryScanLogProvider = StateProvider<LibraryScanLogState>((_) {
  assert(kDebugMode, 'libraryScanLogProvider must only be used in debug builds');
  return LibraryScanLogState.idle;
});
