import 'package:drift/drift.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/database/tables/signal_events_table.dart';
import 'package:nightingale/core/database/tables/taste_scores_table.dart';

part 'signal_dao.g.dart';

@DriftAccessor(tables: [SignalEventsTable, TasteScoresTable])
class SignalDao extends DatabaseAccessor<AppDatabase>
    with _$SignalDaoMixin {
  SignalDao(super.db);

  // ── Signal events ────────────────────────────────────────────────────────

  Future<void> insertEvent(SignalEventsTableCompanion row) =>
      into(signalEventsTable).insert(row);

  /// Returns all signal events. Callers decrypt fingerprints in memory.
  Future<List<SignalEventsTableData>> getAllEvents() =>
      select(signalEventsTable).get();

  /// Returns events newer than [sinceMs] (epoch ms). For network ingestion queries.
  Future<List<SignalEventsTableData>> getEventsSince(int sinceMs) =>
      (select(signalEventsTable)
            ..where((t) => t.timestampUtcMs.isBiggerOrEqualValue(sinceMs)))
          .get();

  // ── Taste scores ─────────────────────────────────────────────────────────

  /// Inserts or replaces the score row for an encrypted fingerprint.
  Future<void> upsertScore(TasteScoresTableCompanion row) =>
      into(tasteScoresTable).insertOnConflictUpdate(row);

  /// Returns all taste score rows. Callers decrypt fingerprints in memory.
  Future<List<TasteScoresTableData>> getAllScores() =>
      select(tasteScoresTable).get();

  /// Adds [delta] to the existing score for an encrypted fingerprint,
  /// or creates the row with [delta] as the initial score.
  Future<void> incrementScore({
    required String encryptedFingerprint,
    required double delta,
  }) async {
    final existing = await (select(tasteScoresTable)
          ..where((t) => t.trackFingerprint.equals(encryptedFingerprint)))
        .getSingleOrNull();
    final newScore = (existing?.score ?? 0.0) + delta;
    await upsertScore(
      TasteScoresTableCompanion(
        trackFingerprint: Value(encryptedFingerprint),
        score: Value(newScore),
      ),
    );
  }
}
