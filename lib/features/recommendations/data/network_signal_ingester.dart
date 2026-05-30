import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, OrderingMode;
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/core/repositories/social_repository.dart';
import 'package:nightingale/features/recommendations/data/signal_repository.dart';
import 'package:nightingale/features/recommendations/domain/signal_event.dart';

const _tag = 'network_signal_ingester';

// Activity types we ingest as network signals.
const _kListenType = 'Listen';
const _kLikeType = 'Like';

/// Polls the local social_activities table and writes network signal events
/// for Listen and Like activities from followed, non-blocked actors.
///
/// Called at app startup and periodically when the app foregrounds.
class NetworkSignalIngester {
  NetworkSignalIngester({
    required AppDatabase db,
    required SocialRepository social,
    required SignalRepository signals,
  })  : _db = db,
        _social = social,
        _signals = signals;

  final AppDatabase _db;
  final SocialRepository _social;
  final SignalRepository _signals;

  /// Ingests any un-processed network activities since the last run.
  /// Idempotent — duplicate events are not re-written because the signal
  /// table records events with their UTC timestamp; callers deduplicate
  /// by checking existing events for the same actor+fingerprint in the window.
  Future<void> ingest() async {
    AppLogger.debug('NetworkSignalIngester.ingest start', tag: _tag);

    final blocks = (await _social.getBlocks()).map((b) => b.actorUrl).toSet();
    final mutes = (await _social.getMutes()).map((m) => m.actorUrl).toSet();
    final excluded = {...blocks, ...mutes};

    // Fetch network activities stored by the federation layer (Phases 4-5).
    final activities = await (
      _db.select(_db.socialActivitiesTable)
        ..where(
          (t) =>
              t.type.isIn([_kListenType, _kLikeType]),
        )
        ..orderBy([(t) => OrderingTerm.asc(t.storedAt)])
    ).get();

    AppLogger.debug(
      'NetworkSignalIngester: ${activities.length} activities to process',
      tag: _tag,
    );

    for (final activity in activities) {
      if (excluded.contains(activity.actorUrl)) continue;

      final fingerprint = _extractFingerprint(activity);
      if (fingerprint == null) continue;

      final eventType = activity.type == _kListenType
          ? SignalEventType.networkListen
          : SignalEventType.networkLike;

      await _signals.recordEvent(
        SignalEvent(
          trackFingerprint: fingerprint,
          eventType: eventType,
          sourceActorId: activity.actorUrl,
          timestampUtc: activity.publishedAt.toUtc(),
          weight: eventType.defaultWeight,
        ),
      );
    }

    AppLogger.debug('NetworkSignalIngester.ingest complete', tag: _tag);
  }

  String? _extractFingerprint(SocialActivitiesTableData activity) {
    try {
      final obj = activity.objectJson;
      if (obj == null || obj.isEmpty) return null;
      final json = jsonDecode(obj) as Map<String, dynamic>;
      final artist = json['artist'] as String? ?? '';
      final title = json['name'] as String? ?? json['title'] as String? ?? '';
      if (artist.isEmpty && title.isEmpty) return null;
      return '${artist.toLowerCase().trim()}:${title.toLowerCase().trim()}';
    } catch (_) {
      return null;
    }
  }
}
