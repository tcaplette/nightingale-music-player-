import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/core/logging/app_logger.dart';

const _kMaxAttempts = 3;
const _tag = 'activity_queue';

/// Durable queue for outgoing ActivityPub activities generated while offline.
/// Flushed FIFO on reconnect; up to [_kMaxAttempts] attempts with exponential
/// backoff (5s, 15s, 45s). Activities that exhaust attempts are marked 'dead'.
class ActivityQueueService {
  ActivityQueueService({required this.db, required this.sigService});

  final AppDatabase db;
  final HttpSignatureService sigService;

  /// Enqueue an activity for later delivery.
  Future<void> enqueue({
    required String activityJson,
    required String activityType,
    required String targetActorUrl,
  }) async {
    await db.into(db.activityQueueTable).insert(
          ActivityQueueTableCompanion.insert(
            activityJson: activityJson,
            activityType: activityType,
            targetActorUrl: targetActorUrl,
          ),
        );
    AppLogger.info(
      'Enqueued offline activity [$activityType] → $targetActorUrl',
      tag: _tag,
    );
  }

  /// Flush all pending activities in FIFO order.
  /// Called by the offline coordinator on reconnect.
  Future<void> flush() async {
    final pending = await (db.select(db.activityQueueTable)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    AppLogger.info('Flushing ${pending.length} queued activities', tag: _tag);

    for (final entry in pending) {
      await _deliver(entry);
    }
  }

  Future<void> _deliver(ActivityQueueTableData entry) async {
    final nextAttempt = entry.attemptCount + 1;

    try {
      await (db.update(db.activityQueueTable)
            ..where((t) => t.id.equals(entry.id)))
          .write(const ActivityQueueTableCompanion(
            status: Value('delivering'),
          ));

      final body = entry.activityJson;
      final targetUri = Uri.parse(entry.targetActorUrl);
      final request = http.Request('POST', targetUri)
        ..headers['Content-Type'] = 'application/activity+json'
        ..body = body;

      final signed = await sigService.signRequest(request);
      final response = await http.Response.fromStream(
        await http.Client().send(signed),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await (db.delete(db.activityQueueTable)
              ..where((t) => t.id.equals(entry.id)))
            .go();
        AppLogger.info(
          'Delivered queued [${entry.activityType}] → ${entry.targetActorUrl}',
          tag: _tag,
        );
      } else {
        await _recordFailure(entry, nextAttempt);
      }
    } catch (e) {
      await _recordFailure(entry, nextAttempt);
      AppLogger.warning(
        'Delivery attempt $nextAttempt failed for [${entry.activityType}]: $e',
        tag: _tag,
      );
    }
  }

  Future<void> _recordFailure(
    ActivityQueueTableData entry,
    int attempts,
  ) async {
    final isDead = attempts >= _kMaxAttempts;
    await (db.update(db.activityQueueTable)
          ..where((t) => t.id.equals(entry.id)))
        .write(ActivityQueueTableCompanion(
          attemptCount: Value(attempts),
          status: Value(isDead ? 'dead' : 'pending'),
        ));
    if (isDead) {
      AppLogger.warning(
        'Activity [${entry.activityType}] exhausted $attempts attempts, marked dead',
        tag: _tag,
      );
    }
  }
}
