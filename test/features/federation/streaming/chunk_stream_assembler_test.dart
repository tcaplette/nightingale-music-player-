import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/federation/streaming/chunk_cache_manager.dart';
import 'package:nightingale/features/federation/streaming/chunk_manifest.dart';
import 'package:nightingale/features/federation/streaming/chunk_stream_assembler.dart';

const _kChunkSize = 512 * 1024;

AppDatabase _inMemoryDb() => AppDatabase(NativeDatabase.memory());

/// Builds a manifest and pre-populates the cache with generated chunk bytes.
Future<({ChunkManifest manifest, ChunkCacheManager cache, AppDatabase db})>
    _buildFixture({
  required int totalBytes,
  int seed = 0xAB,
}) async {
  final db = _inMemoryDb();
  final cache = ChunkCacheManager(db: db);

  final fullBytes = Uint8List.fromList(List<int>.filled(totalBytes, seed));
  final chunks = ChunkSplitter.split(fullBytes);

  for (final c in chunks) {
    await cache.writeChunk(
      Uint8List.fromList(sha256.convert(c.data).bytes),
      c.data,
    );
  }

  final manifest = ChunkManifest(
    trackId: 1,
    sourceActorUrl: 'http://example.com/users/alice',
    chunkHashes: chunks.map((c) => c.hash).toList(),
    totalSizeBytes: totalBytes,
    fetchedAt: DateTime.now(),
  );

  return (manifest: manifest, cache: cache, db: db);
}

Future<Uint8List> _collect(Stream<List<int>> stream) async {
  final parts = <int>[];
  await for (final chunk in stream) {
    parts.addAll(chunk);
  }
  return Uint8List.fromList(parts);
}

void main() {
  group('ChunkStreamAssembler', () {
    ChunkStreamAssembler _assembler(
      ChunkManifest manifest,
      ChunkCacheManager cache,
    ) =>
        ChunkStreamAssembler(
          manifest: manifest,
          cache: cache,
          onMissingChunk: (_) async => null, // no remote fetch in unit tests
        );

    test('full-file request returns all bytes in order', () async {
      final f = await _buildFixture(totalBytes: 3 * _kChunkSize);
      final asm = _assembler(f.manifest, f.cache);
      final resp = await asm.request();
      final data = await _collect(resp.stream);
      expect(data.length, 3 * _kChunkSize);
      expect(data.every((b) => b == 0xAB), isTrue);
      await f.db.close();
    });

    test('byte-range within a single chunk returns correct slice', () async {
      final f = await _buildFixture(totalBytes: 2 * _kChunkSize);
      final asm = _assembler(f.manifest, f.cache);
      // Request bytes 100–199 (within chunk 0)
      final resp = await asm.request(100, 200);
      final data = await _collect(resp.stream);
      expect(data.length, 100);
      expect(data.every((b) => b == 0xAB), isTrue);
      await f.db.close();
    });

    test('byte-range spanning a chunk boundary assembles correctly', () async {
      final f = await _buildFixture(totalBytes: 2 * _kChunkSize);
      final asm = _assembler(f.manifest, f.cache);
      // Straddle boundary between chunk 0 and chunk 1
      final start = _kChunkSize - 50;
      final end = _kChunkSize + 49;
      final resp = await asm.request(start, end + 1);
      final data = await _collect(resp.stream);
      expect(data.length, 100);
      await f.db.close();
    });

    test('seek resets stream to new position without re-downloading', () async {
      final f = await _buildFixture(totalBytes: 3 * _kChunkSize);
      final asm = _assembler(f.manifest, f.cache);

      // First request from beginning
      await asm.request(0, _kChunkSize);

      // Seek forward to chunk 2 — should work with cached data
      final seekResp = await asm.request(2 * _kChunkSize, 3 * _kChunkSize);
      final data = await _collect(seekResp.stream);
      expect(data.length, _kChunkSize);
      await f.db.close();
    });

    test('missing chunk triggers onMissingChunk callback', () async {
      final db = _inMemoryDb();
      final cache = ChunkCacheManager(db: db);

      // Don't populate cache — force on-demand fetch
      const fakeHash = 'aabbccddeeff00112233445566778899'
          'aabbccddeeff00112233445566778899';
      final manifest = ChunkManifest(
        trackId: 2,
        sourceActorUrl: 'http://example.com/users/bob',
        chunkHashes: [fakeHash],
        totalSizeBytes: 1024,
        fetchedAt: DateTime.now(),
      );

      var fetchCalled = false;
      final asm = ChunkStreamAssembler(
        manifest: manifest,
        cache: cache,
        onMissingChunk: (hash) async {
          fetchCalled = true;
          return Uint8List.fromList(List<int>.filled(1024, 0xCC));
        },
      );

      final resp = await asm.request();
      await _collect(resp.stream);
      expect(fetchCalled, isTrue);
      await db.close();
    });

    test('fetch failure emits stream error', () async {
      final db = _inMemoryDb();
      final cache = ChunkCacheManager(db: db);

      const fakeHash = 'aabbccddeeff00112233445566778899'
          'aabbccddeeff00112233445566778899';
      final manifest = ChunkManifest(
        trackId: 3,
        sourceActorUrl: 'http://example.com/users/carol',
        chunkHashes: [fakeHash],
        totalSizeBytes: 1024,
        fetchedAt: DateTime.now(),
      );

      final asm = ChunkStreamAssembler(
        manifest: manifest,
        cache: cache,
        onMissingChunk: (_) async => null, // simulate unavailable
      );

      final resp = await asm.request();
      expect(
        () => _collect(resp.stream),
        throwsA(isA<StateError>()),
      );
      await db.close();
    });
  });
}
