import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/logging/app_logger.dart';

const _tag = 'db_integrity';

enum IntegrityCheckResult { ok, repaired, unrecoverable }

/// Runs `PRAGMA integrity_check` on startup and attempts staged recovery.
///
/// Stage 1: WAL checkpoint + reopen (transparent, no data loss).
/// Stage 2: If unrecoverable, report [IntegrityCheckResult.unrecoverable]
///          so the caller can prompt the user and initiate a rescan.
class DatabaseIntegrityService {
  DatabaseIntegrityService({required this.db});

  final AppDatabase db;

  Future<IntegrityCheckResult> checkAndRepair() async {
    AppLogger.info('Running DB integrity check', tag: _tag);

    final isOk = await _runIntegrityCheck();
    if (isOk) {
      AppLogger.info('DB integrity check passed', tag: _tag);
      return IntegrityCheckResult.ok;
    }

    AppLogger.warning('DB integrity check failed — attempting WAL checkpoint', tag: _tag);

    // Stage 1: WAL checkpoint — flushes WAL into the main database file
    try {
      await db.customStatement('PRAGMA wal_checkpoint(FULL)');
      final okAfterCheckpoint = await _runIntegrityCheck();
      if (okAfterCheckpoint) {
        AppLogger.info('DB integrity restored after WAL checkpoint', tag: _tag);
        return IntegrityCheckResult.repaired;
      }
    } catch (e) {
      AppLogger.error('WAL checkpoint failed: $e', tag: _tag);
    }

    // Stage 2: Unrecoverable — caller must handle (prompt user, rescan)
    AppLogger.error('DB is unrecoverable — caller must initiate rescan', tag: _tag);
    return IntegrityCheckResult.unrecoverable;
  }

  Future<bool> _runIntegrityCheck() async {
    try {
      final result = await db
          .customSelect('PRAGMA integrity_check')
          .getSingleOrNull();
      final value = result?.data['integrity_check'] as String?;
      return value == 'ok';
    } catch (e) {
      AppLogger.error('integrity_check threw: $e', tag: _tag);
      return false;
    }
  }
}
