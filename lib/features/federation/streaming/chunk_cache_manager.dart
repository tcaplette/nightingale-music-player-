import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/streaming/chunk_manifest.dart';

const _tag = 'chunk_cache';

class InsufficientCacheSpaceException implements Exception {
  const InsufficientCacheSpaceException(this.needed, this.available);
  final int needed;
  final int available;

  @override
  String toString() =>
      'InsufficientCacheSpaceException: need $needed bytes but only $available '
      'bytes can be freed (all remaining chunks are pinned)';
}

/// Content-addressed chunk store backed by a single SQLite BLOB table.
///
/// Chunks are keyed by their SHA-256 hash (raw bytes). LRU eviction enforces
/// a configurable size cap (default 500 MB). Pinned chunks are excluded from
/// eviction and protect in-queue audio from being deleted mid-play.
class ChunkCacheManager {
  ChunkCacheManager({
    required AppDatabase db,
    ChunkManifestRepository? manifestRepository,
  })  : _db = db,
        _manifests = manifestRepository;

  final AppDatabase _db;
  final ChunkManifestRepository? _manifests;
  int _maxSizeBytes = 500 * 1024 * 1024;

  void setMaxSize(int bytes) {
    _maxSizeBytes = bytes;
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Inserts [data] keyed by [hash]. Idempotent — duplicate writes are ignored.
  Future<void> writeChunk(Uint8List hash, Uint8List data) async {
    await _ensureSpace(data.length);

    await _db.into(_db.chunksTable).insertOnConflictUpdate(
          ChunksTableCompanion.insert(
            hash: hash,
            data: data,
            sizeBytes: data.length,
            lastAccessed: Value(DateTime.now()),
          ),
        );

    AppLogger.debug(
      'ChunkCacheManager: wrote chunk ${_hex(hash)} (${data.length} bytes)',
      tag: _tag,
    );
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Returns the chunk bytes for [hash], or null if not cached.
  Future<Uint8List?> readChunk(Uint8List hash) async {
    final row = await (_db.select(_db.chunksTable)
          ..where((t) => t.hash.equals(hash)))
        .getSingleOrNull();

    if (row == null) return null;

    await (_db.update(_db.chunksTable)
          ..where((t) => t.hash.equals(hash)))
        .write(ChunksTableCompanion(lastAccessed: Value(DateTime.now())));

    return Uint8List.fromList(row.data);
  }

  // ── Pin / Unpin ────────────────────────────────────────────────────────────

  Future<void> pinChunk(Uint8List hash) async {
    await (_db.update(_db.chunksTable)..where((t) => t.hash.equals(hash)))
        .write(const ChunksTableCompanion(isPinned: Value(true)));
  }

  Future<void> unpinChunk(Uint8List hash) async {
    await (_db.update(_db.chunksTable)..where((t) => t.hash.equals(hash)))
        .write(const ChunksTableCompanion(isPinned: Value(false)));
  }

  // ── Eviction ───────────────────────────────────────────────────────────────

  Future<void> _ensureSpace(int neededBytes) async {
    final total = await _getTotalSize();
    if (total + neededBytes <= _maxSizeBytes) return;

    final evictable = await (_db.select(_db.chunksTable)
          ..where((t) => t.isPinned.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.lastAccessed)]))
        .get();

    int freed = 0;
    for (final row in evictable) {
      if (total + neededBytes - freed <= _maxSizeBytes) break;
      freed += row.sizeBytes;
      await (_db.delete(_db.chunksTable)
            ..where((t) => t.hash.equals(row.hash)))
          .go();
      AppLogger.debug(
        'ChunkCacheManager: evicted ${_hex(Uint8List.fromList(row.hash))}',
        tag: _tag,
      );
    }

    final stillNeeded = total + neededBytes - freed;
    if (stillNeeded > _maxSizeBytes) {
      throw InsufficientCacheSpaceException(
        neededBytes,
        _maxSizeBytes - (total - freed),
      );
    }

    // Prune manifests whose chunks were all evicted.
    if (_manifests != null && freed > 0) {
      final live = await _getLiveHashes();
      await _manifests.pruneOrphanedManifests(live);
    }
  }

  Future<Set<String>> _getLiveHashes() async {
    final rows = await _db.select(_db.chunksTable).get();
    return rows
        .map((r) => _hex(Uint8List.fromList(r.hash)))
        .toSet();
  }

  Future<int> _getTotalSize() async {
    final rows = await _db.select(_db.chunksTable).get();
    return rows.fold<int>(0, (sum, r) => sum + r.sizeBytes);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
