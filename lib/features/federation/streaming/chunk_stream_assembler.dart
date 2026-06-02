import 'dart:async';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/streaming/chunk_cache_manager.dart';
import 'package:nightingale/features/federation/streaming/chunk_manifest.dart';

const _tag = 'chunk_assembler';
const _kChunkSize = 512 * 1024; // 512 KB — must match ChunkSplitter
const _prefetchAhead = 2; // chunks to load ahead of current

/// Assembles a sequence of cached audio chunks into a [StreamAudioSource]
/// compatible with just_audio.
///
/// Maps byte-range requests to chunk indices, prefetches the next 2 chunks,
/// and fetches any missing chunks on-demand via [onMissingChunk].
class ChunkStreamAssembler extends StreamAudioSource {
  ChunkStreamAssembler({
    required ChunkManifest manifest,
    required ChunkCacheManager cache,
    required Future<Uint8List?> Function(String hash) onMissingChunk,
    dynamic tag,
  })  : _manifest = manifest,
        _cache = cache,
        _onMissingChunk = onMissingChunk,
        super(tag: tag);

  final ChunkManifest _manifest;
  final ChunkCacheManager _cache;
  final Future<Uint8List?> Function(String hash) _onMissingChunk;

  // In-memory buffer: chunkIndex → bytes
  final Map<int, Uint8List> _buffer = {};

  // ── StreamAudioSource API ────────────────────────────────────────────────

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final totalLength = _manifest.totalSizeBytes;
    final rangeStart = start ?? 0;
    final rangeEnd = (end ?? totalLength) - 1;
    final contentLength = rangeEnd - rangeStart + 1;

    AppLogger.debug(
      'ChunkStreamAssembler: request bytes=$rangeStart-$rangeEnd / $totalLength',
      tag: _tag,
    );

    // Discard buffered chunks that are no longer needed.
    _evictBufferBefore(rangeStart);

    // Prefetch chunks starting from the range start position.
    final startChunk = rangeStart ~/ _kChunkSize;
    _prefetch(startChunk);

    final stream = _assembleStream(rangeStart, rangeEnd);

    return StreamAudioResponse(
      sourceLength: totalLength,
      contentLength: contentLength,
      offset: rangeStart,
      contentType: 'audio/mpeg',
      stream: stream,
    );
  }

  // ── Assembly ───────────────────────────────────────────────────────────────

  Stream<List<int>> _assembleStream(int start, int end) async* {
    var position = start;

    while (position <= end) {
      final chunkIndex = position ~/ _kChunkSize;
      final chunkData = await _getChunk(chunkIndex);

      final chunkStart = chunkIndex * _kChunkSize;
      final sliceFrom = position - chunkStart;
      final sliceTo = ((chunkStart + chunkData.length - 1).clamp(0, end)) -
          chunkStart +
          1;

      yield chunkData.sublist(sliceFrom, sliceTo);

      position = chunkStart + sliceTo;

      // Trigger prefetch as we advance.
      _prefetch(chunkIndex + 1);
    }
  }

  Future<Uint8List> _getChunk(int index) async {
    if (_buffer.containsKey(index)) {
      return _buffer[index]!;
    }

    final hash = _manifest.chunkHashes[index];
    final rawHash = _hexToBytes(hash);

    var data = await _cache.readChunk(rawHash);
    if (data == null) {
      AppLogger.info(
        'ChunkStreamAssembler: chunk $index missing — fetching on demand',
        tag: _tag,
      );
      data = await _onMissingChunk(hash);
      if (data == null) {
        throw StateError(
          'ChunkStreamAssembler: chunk $index ($hash) could not be fetched',
        );
      }
      await _cache.writeChunk(rawHash, data);
    }

    _buffer[index] = data;
    return data;
  }

  // ── Prefetch ───────────────────────────────────────────────────────────────

  void _prefetch(int fromChunk) {
    final last = _manifest.chunkHashes.length - 1;
    for (var i = fromChunk; i <= (fromChunk + _prefetchAhead).clamp(0, last); i++) {
      if (!_buffer.containsKey(i)) {
        _loadChunkInBackground(i);
      }
    }
  }

  void _loadChunkInBackground(int index) {
    // Fire-and-forget; errors are silently ignored — the main assembly path
    // will fetch on demand if the prefetch didn't land in time.
    _getChunk(index).ignore();
  }

  // ── Buffer management ──────────────────────────────────────────────────────

  void _evictBufferBefore(int byteOffset) {
    if (byteOffset <= 0) return;
    final cutoffChunk = (byteOffset ~/ _kChunkSize) - 1;
    _buffer.removeWhere((idx, _) => idx < cutoffChunk);
  }

  // ── Hex helper ─────────────────────────────────────────────────────────────

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}
