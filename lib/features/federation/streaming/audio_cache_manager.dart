import 'dart:io';

import 'package:drift/drift.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/logging/app_logger.dart';

const _tag = 'audio_cache';

/// Manages local disk cache for remote audio files.
class AudioCacheManager {
  AudioCacheManager({required AppDatabase db}) : _db = db;

  final AppDatabase _db;
  // Phase 7: 500 MB limit per spec; protected by pinned flag for in-queue tracks.
  int _maxSizeBytes = 500 * 1024 * 1024;

  void setMaxSize(int bytes) {
    _maxSizeBytes = bytes;
  }

  /// Returns the local file path if cached, null otherwise.
  Future<String?> getCachedPath(String trackId, String sourceActorUrl) async {
    final row = await (_db.select(_db.audioCacheTable)
          ..where((t) =>
              t.trackId.equals(trackId) & t.sourceActorUrl.equals(sourceActorUrl)))
        .getSingleOrNull();

    if (row == null) return null;

    final file = File(row.localPath);
    if (!file.existsSync()) {
      // Cache entry exists but file was deleted externally
      await _deleteEntry(trackId, sourceActorUrl);
      return null;
    }

    // Update last accessed
    await (_db.update(_db.audioCacheTable)
          ..where((t) =>
              t.trackId.equals(trackId) & t.sourceActorUrl.equals(sourceActorUrl)))
        .write(AudioCacheTableCompanion(lastAccessed: Value(DateTime.now())));

    return row.localPath;
  }

  /// Stores a downloaded audio file in the cache.
  Future<void> cacheFile({
    required String trackId,
    required String sourceActorUrl,
    required String localPath,
  }) async {
    final file = File(localPath);
    final size = await file.length();

    // Check if we need to evict
    await _ensureSpace(size);

    await _db.into(_db.audioCacheTable).insertOnConflictUpdate(
          AudioCacheTableCompanion.insert(
            trackId: trackId,
            sourceActorUrl: sourceActorUrl,
            localPath: localPath,
            sizeBytes: size,
            lastAccessed: Value(DateTime.now()),
          ),
        );

    AppLogger.info('Cached audio file: $trackId ($size bytes)', tag: _tag);
  }

  /// Pins a file so it won't be evicted.
  Future<void> pinFile(String trackId, String sourceActorUrl) async {
    await (_db.update(_db.audioCacheTable)
          ..where((t) =>
              t.trackId.equals(trackId) & t.sourceActorUrl.equals(sourceActorUrl)))
        .write(const AudioCacheTableCompanion(isPinned: Value(true)));
  }

  /// Unpins a file.
  Future<void> unpinFile(String trackId, String sourceActorUrl) async {
    await (_db.update(_db.audioCacheTable)
          ..where((t) =>
              t.trackId.equals(trackId) & t.sourceActorUrl.equals(sourceActorUrl)))
        .write(const AudioCacheTableCompanion(isPinned: Value(false)));
  }

  /// Ensures there's enough space by evicting LRU entries.
  Future<void> _ensureSpace(int neededBytes) async {
    final totalSize = await _getTotalCacheSize();
    if (totalSize + neededBytes <= _maxSizeBytes) return;

    // Get evictable entries (not pinned), ordered by last accessed
    final evictable = await (_db.select(_db.audioCacheTable)
          ..where((t) => t.isPinned.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.lastAccessed)]))
        .get();

    int freed = 0;
    for (final entry in evictable) {
      if (totalSize + neededBytes - freed <= _maxSizeBytes) break;

      final file = File(entry.localPath);
      if (file.existsSync()) {
        freed += entry.sizeBytes;
        await file.delete();
      }
      await _deleteEntry(entry.trackId, entry.sourceActorUrl);
    }
  }

  Future<int> _getTotalCacheSize() async {
    final rows = await _db.select(_db.audioCacheTable).get();
    return rows.fold<int>(0, (sum, r) => sum + r.sizeBytes);
  }

  Future<void> _deleteEntry(String trackId, String sourceActorUrl) async {
    await (_db.delete(_db.audioCacheTable)
          ..where((t) =>
              t.trackId.equals(trackId) & t.sourceActorUrl.equals(sourceActorUrl)))
        .go();
  }
}
