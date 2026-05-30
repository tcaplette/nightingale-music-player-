import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/database/tables/signal_events_table.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/recommendations/data/encrypted_signal_store.dart';
import 'package:nightingale/features/recommendations/data/signal_dao.dart';
import 'package:nightingale/features/recommendations/data/taste_profile_key_store.dart';
import 'package:nightingale/features/recommendations/domain/signal_event.dart';

class SignalRepository {
  SignalRepository({
    required SignalDao dao,
    required EncryptedSignalStore encryptedStore,
  })  : _dao = dao,
        _encryptedStore = encryptedStore;

  final SignalDao _dao;
  final EncryptedSignalStore _encryptedStore;

  Future<void> recordEvent(SignalEvent event) async {
    final encrypted = await _encryptedStore.encryptFields(
      fingerprint: event.trackFingerprint,
      actorId: event.sourceActorId,
    );
    await _dao.insertEvent(
      SignalEventsTableCompanion.insert(
        trackFingerprint: encrypted.fingerprint,
        eventType: event.eventType.value,
        sourceActorId: Value(encrypted.actorId),
        timestampUtcMs: event.timestampUtc.millisecondsSinceEpoch,
        weight: event.weight,
      ),
    );
    await _dao.incrementScore(
      encryptedFingerprint: encrypted.fingerprint,
      delta: event.weight,
    );
  }

  Future<List<SignalEvent>> getAllEvents() async {
    final rows = await _dao.getAllEvents();
    final events = <SignalEvent>[];
    for (final row in rows) {
      events.add(await _encryptedStore.decryptEvent(
        encryptedFingerprint: row.trackFingerprint,
        eventTypeStr: row.eventType,
        encryptedActorId: row.sourceActorId,
        timestampUtcMs: row.timestampUtcMs,
        weight: row.weight,
      ));
    }
    return events;
  }

  Future<Map<String, double>> getAllScores() async {
    final rows = await _dao.getAllScores();
    final scores = <String, double>{};
    for (final row in rows) {
      final fingerprint =
          await _encryptedStore.decryptFingerprint(row.trackFingerprint);
      scores[fingerprint] = row.score;
    }
    return scores;
  }

  Future<List<SignalEvent>> getRecentNetworkEvents({
    required Duration window,
    required List<String> actorIds,
  }) async {
    if (actorIds.isEmpty) return [];
    final sinceMs =
        DateTime.now().subtract(window).millisecondsSinceEpoch;
    final rows = await _dao.getEventsSince(sinceMs);
    final events = <SignalEvent>[];
    for (final row in rows) {
      if (row.sourceActorId == null) continue;
      final event = await _encryptedStore.decryptEvent(
        encryptedFingerprint: row.trackFingerprint,
        eventTypeStr: row.eventType,
        encryptedActorId: row.sourceActorId,
        timestampUtcMs: row.timestampUtcMs,
        weight: row.weight,
      );
      if (actorIds.contains(event.sourceActorId)) {
        events.add(event);
      }
    }
    return events;
  }
}

final signalRepositoryProvider = Provider<SignalRepository>((ref) {
  final db = sl<AppDatabase>();
  final keyStore = sl<TasteProfileKeyStore>();
  return SignalRepository(
    dao: db.signalDao,
    encryptedStore: EncryptedSignalStore(keyStore),
  );
});
