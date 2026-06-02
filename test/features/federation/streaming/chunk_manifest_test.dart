import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/federation/streaming/chunk_cache_manager.dart';
import 'package:nightingale/features/federation/streaming/chunk_manifest.dart';

AppDatabase _inMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  group('ChunkSplitter', () {
    test('splits file into expected chunk count at exactly 512 KB boundary',
        () {
      final bytes = Uint8List(5 * 512 * 1024); // 2.5 MB → 5 chunks
      final chunks = ChunkSplitter.split(bytes);
      expect(chunks.length, 5);
      for (final c in chunks) {
        expect(c.data.length, 512 * 1024);
      }
    });

    test('last chunk is smaller than 512 KB for non-multiple size', () {
      final bytes = Uint8List(512 * 1024 + 100); // 512 KB + 100 bytes
      final chunks = ChunkSplitter.split(bytes);
      expect(chunks.length, 2);
      expect(chunks[0].data.length, 512 * 1024);
      expect(chunks[1].data.length, 100);
    });

    test('file smaller than 512 KB produces exactly one chunk', () {
      final bytes = Uint8List(1024);
      final chunks = ChunkSplitter.split(bytes);
      expect(chunks.length, 1);
      expect(chunks[0].data.length, 1024);
    });

    test('chunk hashes are correct SHA-256', () {
      final bytes = Uint8List.fromList(List<int>.generate(1024, (i) => i % 256));
      final chunks = ChunkSplitter.split(bytes);
      final expectedHash = sha256.convert(bytes).toString();
      expect(chunks[0].hash, expectedHash);
    });

    test('identical byte sequences produce identical hashes', () {
      final a = Uint8List.fromList(List<int>.filled(1024, 0xFF));
      final b = Uint8List.fromList(List<int>.filled(1024, 0xFF));
      final chunksA = ChunkSplitter.split(a);
      final chunksB = ChunkSplitter.split(b);
      expect(chunksA[0].hash, chunksB[0].hash);
    });
  });

  group('ChunkManifestRepository', () {
    late AppDatabase db;
    late ChunkManifestRepository repo;

    setUp(() {
      db = _inMemoryDb();
      repo = ChunkManifestRepository(db: db);
    });

    tearDown(() => db.close());

    ChunkManifest _manifest({int trackId = 1, List<String>? hashes}) =>
        ChunkManifest(
          trackId: trackId,
          sourceActorUrl: 'http://example.com/users/alice',
          chunkHashes: hashes ?? ['aabbcc', 'ddeeff'],
          totalSizeBytes: 2048,
          fetchedAt: DateTime(2026, 1, 1),
        );

    test('save and retrieve round-trip', () async {
      final m = _manifest();
      await repo.saveManifest(m);
      final result = await repo.getManifest(m.trackId, m.sourceActorUrl);
      expect(result, isNotNull);
      expect(result!.chunkHashes, equals(m.chunkHashes));
      expect(result.totalSizeBytes, m.totalSizeBytes);
    });

    test('getManifest returns null for unknown track', () async {
      expect(await repo.getManifest(999, 'http://none'), isNull);
    });

    test('deleteManifest removes the row', () async {
      final m = _manifest();
      await repo.saveManifest(m);
      await repo.deleteManifest(m.trackId, m.sourceActorUrl);
      expect(await repo.getManifest(m.trackId, m.sourceActorUrl), isNull);
    });

    test('pruneOrphanedManifests removes manifest when all hashes evicted',
        () async {
      final m = _manifest(hashes: ['aabb', 'ccdd']);
      await repo.saveManifest(m);

      // Neither hash is in the live set
      await repo.pruneOrphanedManifests({});
      expect(await repo.getManifest(m.trackId, m.sourceActorUrl), isNull);
    });

    test('pruneOrphanedManifests keeps manifest when some hashes still live',
        () async {
      final m = _manifest(hashes: ['aabb', 'ccdd']);
      await repo.saveManifest(m);

      // One hash survives
      await repo.pruneOrphanedManifests({'aabb'});
      expect(await repo.getManifest(m.trackId, m.sourceActorUrl), isNotNull);
    });
  });

  group('ChunkCacheManager — manifest cascade on eviction', () {
    late AppDatabase db;
    late ChunkManifestRepository manifests;
    late ChunkCacheManager cache;

    setUp(() {
      db = _inMemoryDb();
      manifests = ChunkManifestRepository(db: db);
      cache = ChunkCacheManager(db: db, manifestRepository: manifests);
    });

    tearDown(() => db.close());

    test('manifest removed when all its chunks are evicted', () async {
      cache.setMaxSize(1024);

      final bytes = Uint8List(512);
      final hash = sha256.convert(bytes).toString();
      final rawHash = Uint8List.fromList(
        List<int>.generate(32, (i) => i),
      );

      await cache.writeChunk(rawHash, bytes);

      final manifest = ChunkManifest(
        trackId: 1,
        sourceActorUrl: 'http://example.com/users/alice',
        chunkHashes: [hash],
        totalSizeBytes: 512,
        fetchedAt: DateTime.now(),
      );
      await manifests.saveManifest(manifest);

      // Write new data that forces eviction of rawHash
      final rawHash2 = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
      await cache.writeChunk(rawHash2, Uint8List(1024));

      // Manifest should be pruned
      expect(await manifests.getManifest(1, 'http://example.com/users/alice'),
          isNull);
    });
  });
}
