import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/deduplication/chromaprint_ffi.dart';
import 'package:nightingale/features/library/models/track_model.dart';

const _tag = 'acoustic_fingerprint';

/// Acoustic fingerprinting for deduplication.
/// 
/// Uses a simplified chromaprint-inspired approach:
/// - Extracts perceptual features from audio (spectral centroid, zero-crossing rate)
/// - Generates a compact hash representation
/// - Stores in FingerprintsTable for cross-node comparison
/// 
/// NOTE: Full chromaprint integration would require native FFI to libchromaprint.
/// This implementation provides the schema and service architecture; the actual
/// fingerprint extraction is a placeholder that should be replaced with a proper
/// audio analysis library or FFI binding.
class AcousticFingerprintService {
  AcousticFingerprintService({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  /// Generates a fingerprint for a local audio file.
  /// Returns a base64-encoded fingerprint string.
  Future<String?> fingerprintTrack(int trackId, String filePath) async {
    try {
      // Try chromaprint FFI first
      String? fingerprint;
      if (ChromaprintFFI.isAvailable) {
        // TODO: Decode audio file and extract raw samples for chromaprint
        // fingerprint = await ChromaprintFFI.fingerprint(samples, 44100, 2);
        AppLogger.debug('Chromaprint available but audio decoding not implemented', tag: _tag);
      }

      // Fallback to placeholder
      fingerprint ??= await _generatePlaceholderFingerprint(filePath);

      // Store in database
      await _db.into(_db.fingerprintsTable).insertOnConflictUpdate(
            FingerprintsTableCompanion(
              trackId: Value(trackId),
              chromaprintHash: Value(fingerprint),
              durationMs: const Value(0),
            ),
          );

      AppLogger.info('Fingerprint generated for track $trackId', tag: _tag);
      return fingerprint;
    } catch (e) {
      AppLogger.error('Failed to fingerprint track $trackId', tag: _tag, error: e);
      return null;
    }
  }

  /// Checks whether two tracks are duplicates using ISRC equality first,
  /// falling back to fingerprint comparison when ISRC is absent.
  Future<bool> areDuplicates(TrackModel a, TrackModel b) async {
    final isrcA = a.isrc?.trim();
    final isrcB = b.isrc?.trim();
    if (isrcA != null && isrcA.isNotEmpty && isrcB != null && isrcB.isNotEmpty) {
      final match = isrcA == isrcB;
      AppLogger.debug(
        'ISRC comparison: $isrcA vs $isrcB → ${match ? "match" : "no match"}',
        tag: _tag,
      );
      return match;
    }
    // Fall through to fingerprint comparison
    final duplicates = await findDuplicates(a.id);
    return duplicates.contains(b.id);
  }

  /// Finds potential duplicates by comparing fingerprints.
  /// Returns a list of track IDs that match above the threshold.
  Future<List<int>> findDuplicates(int trackId, {double threshold = 0.85}) async {
    final targetFp = await (_db.select(_db.fingerprintsTable)
          ..where((t) => t.trackId.equals(trackId)))
        .getSingleOrNull();

    if (targetFp == null) return [];

    // Get all other fingerprints
    final allFps = await (_db.select(_db.fingerprintsTable)
          ..where((t) => t.trackId.isNotValue(trackId)))
        .get();

    final duplicates = <int>[];
    for (final fp in allFps) {
      final similarity = _compareFingerprints(targetFp.chromaprintHash, fp.chromaprintHash);
      if (similarity >= threshold) {
        duplicates.add(fp.trackId);
        AppLogger.debug(
          'Duplicate found: ${targetFp.trackId} ~ ${fp.trackId} (similarity: ${similarity.toStringAsFixed(2)})',
          tag: _tag,
        );
      }
    }

    return duplicates;
  }

  /// Compares two fingerprints and returns a similarity score [0.0, 1.0].
  double _compareFingerprints(String fp1, String fp2) {
    // Try chromaprint comparison if available
    if (ChromaprintFFI.isAvailable) {
      return ChromaprintFFI.compare(fp1, fp2);
    }

    // Fallback: bit-error rate comparison on base64 decoded bytes
    if (fp1 == fp2) return 1.0;

    try {
      final bytes1 = base64.decode(fp1);
      final bytes2 = base64.decode(fp2);

      if (bytes1.length != bytes2.length) {
        // Normalize by comparing shorter length
        final minLen = bytes1.length < bytes2.length ? bytes1.length : bytes2.length;
        int matching = 0;
        for (int i = 0; i < minLen; i++) {
          if (bytes1[i] == bytes2[i]) matching++;
        }
        return matching / minLen;
      }

      int matching = 0;
      for (int i = 0; i < bytes1.length; i++) {
        if (bytes1[i] == bytes2[i]) matching++;
      }

      return matching / bytes1.length;
    } catch (e) {
      return 0.0;
    }
  }

  /// Generates a placeholder fingerprint from file metadata.
  Future<String> _generatePlaceholderFingerprint(String filePath) async {
    // In a real implementation, this would:
    // 1. Decode audio file
    // 2. Extract spectral features
    // 3. Run through chromaprint algorithm
    // 4. Return compact fingerprint

    // Placeholder: hash of file path + length
    final bytes = utf8.encode(filePath);
    final hash = List<int>.generate(32, (i) => bytes[i % bytes.length] ^ (i * 7));
    return base64.encode(Uint8List.fromList(hash));
  }

  /// Records a merge decision with provenance.
  Future<void> recordMerge({
    required int canonicalTrackId,
    required int duplicateTrackId,
    required String sourceActorUrl,
    required MergeAction action,
  }) async {
    await _db.into(_db.mergeProvenanceTable).insert(
          MergeProvenanceTableCompanion.insert(
            fingerprintA: canonicalTrackId.toString(),
            fingerprintB: duplicateTrackId.toString(),
            similarityScore: action == MergeAction.mergeToCanonical ? 1.0 : 0.5,
            reason: '${action.name}: $sourceActorUrl',
          ),
        );

    AppLogger.info(
      'Merge recorded: $duplicateTrackId -> $canonicalTrackId (action: ${action.name})',
      tag: _tag,
    );
  }

  /// Gets merge history for a track.
  Future<List<MergeProvenanceTableData>> getMergeHistory(int trackId) async {
    final trackIdStr = trackId.toString();
    return await (_db.select(_db.mergeProvenanceTable)
          ..where((t) =>
              t.fingerprintA.equals(trackIdStr) |
              t.fingerprintB.equals(trackIdStr))
          ..orderBy([(t) => OrderingTerm(expression: t.mergedAt, mode: OrderingMode.desc)]))
        .get();
  }

  /// Reverses a merge by track ID.
  Future<void> unmerge(int trackId) async {
    final trackIdStr = trackId.toString();
    await (_db.delete(_db.mergeProvenanceTable)
          ..where((t) =>
              t.fingerprintA.equals(trackIdStr) |
              t.fingerprintB.equals(trackIdStr)))
        .go();

    AppLogger.info('Merge reversed for track $trackId', tag: _tag);
  }
}

enum MergeAction { keepBoth, mergeToCanonical, replaceWithRemote }
