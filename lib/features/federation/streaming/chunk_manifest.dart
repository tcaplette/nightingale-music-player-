import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:nightingale/core/database/app_database.dart';

const _kChunkSize = 512 * 1024; // 512 KB

/// Ordered list of SHA-256 chunk hashes that constitute a remote audio track.
class ChunkManifest {
  const ChunkManifest({
    required this.trackId,
    required this.sourceActorUrl,
    required this.chunkHashes,
    required this.totalSizeBytes,
    required this.fetchedAt,
  });

  final int trackId;
  final String sourceActorUrl;

  /// Hex-encoded SHA-256 hashes in playback order.
  final List<String> chunkHashes;

  final int totalSizeBytes;
  final DateTime fetchedAt;

  /// Returns the 0-based chunk index that contains [byteOffset].
  int chunkIndexFor(int byteOffset) => byteOffset ~/ _kChunkSize;

  /// Returns the byte offset within its chunk for a given absolute [byteOffset].
  int offsetWithinChunk(int byteOffset) => byteOffset % _kChunkSize;
}

// ── Splitter ────────────────────────────────────────────────────────────────

typedef ChunkEntry = ({String hash, Uint8List data});

/// Splits [bytes] into fixed 512 KB chunks and computes each chunk's SHA-256.
class ChunkSplitter {
  static List<ChunkEntry> split(Uint8List bytes) {
    final result = <ChunkEntry>[];
    var offset = 0;
    while (offset < bytes.length) {
      final end =
          (offset + _kChunkSize).clamp(0, bytes.length);
      final chunk = bytes.sublist(offset, end);
      final hash = sha256.convert(chunk).toString();
      result.add((hash: hash, data: chunk));
      offset = end;
    }
    return result;
  }
}

// ── Repository ───────────────────────────────────────────────────────────────

class ChunkManifestRepository {
  ChunkManifestRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  Future<void> saveManifest(ChunkManifest manifest) async {
    await _db.into(_db.chunkManifestsTable).insertOnConflictUpdate(
          ChunkManifestsTableCompanion.insert(
            trackId: manifest.trackId,
            sourceActorUrl: manifest.sourceActorUrl,
            chunkHashes: jsonEncode(manifest.chunkHashes),
            totalSizeBytes: manifest.totalSizeBytes,
            fetchedAt: Value(manifest.fetchedAt),
          ),
        );
  }

  Future<ChunkManifest?> getManifest(
    int trackId,
    String sourceActorUrl,
  ) async {
    final row = await (_db.select(_db.chunkManifestsTable)
          ..where(
            (t) =>
                t.trackId.equals(trackId) &
                t.sourceActorUrl.equals(sourceActorUrl),
          ))
        .getSingleOrNull();

    if (row == null) return null;

    final hashes = (jsonDecode(row.chunkHashes) as List<dynamic>)
        .cast<String>();

    return ChunkManifest(
      trackId: row.trackId,
      sourceActorUrl: row.sourceActorUrl,
      chunkHashes: hashes,
      totalSizeBytes: row.totalSizeBytes,
      fetchedAt: row.fetchedAt,
    );
  }

  Future<void> deleteManifest(int trackId, String sourceActorUrl) async {
    await (_db.delete(_db.chunkManifestsTable)
          ..where(
            (t) =>
                t.trackId.equals(trackId) &
                t.sourceActorUrl.equals(sourceActorUrl),
          ))
        .go();
  }

  /// Removes manifests whose chunk hashes are no longer present in [liveHashes].
  Future<void> pruneOrphanedManifests(Set<String> liveHashes) async {
    final all = await _db.select(_db.chunkManifestsTable).get();
    for (final row in all) {
      final hashes = (jsonDecode(row.chunkHashes) as List<dynamic>).cast<String>();
      if (hashes.every((h) => !liveHashes.contains(h))) {
        await deleteManifest(row.trackId, row.sourceActorUrl);
      }
    }
  }
}
