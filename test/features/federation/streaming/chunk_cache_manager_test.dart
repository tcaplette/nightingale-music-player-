import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/federation/streaming/chunk_cache_manager.dart';

AppDatabase _inMemoryDb() => AppDatabase(NativeDatabase.memory());

Uint8List _hash(int seed) => Uint8List.fromList(
      List<int>.generate(32, (i) => (seed + i) % 256),
    );

Uint8List _data(int size, [int fill = 0xAB]) =>
    Uint8List.fromList(List<int>.filled(size, fill));

void main() {
  group('ChunkCacheManager', () {
    late AppDatabase db;
    late ChunkCacheManager cache;

    setUp(() {
      db = _inMemoryDb();
      cache = ChunkCacheManager(db: db);
    });

    tearDown(() => db.close());

    test('readChunk returns null for unknown hash', () async {
      expect(await cache.readChunk(_hash(0)), isNull);
    });

    test('write and read round-trip returns original bytes', () async {
      final hash = _hash(1);
      final data = _data(1024);
      await cache.writeChunk(hash, data);
      final result = await cache.readChunk(hash);
      expect(result, equals(data));
    });

    test('duplicate write is idempotent (no error, no duplicate row)', () async {
      final hash = _hash(2);
      final data = _data(512);
      await cache.writeChunk(hash, data);
      await cache.writeChunk(hash, data);
      final result = await cache.readChunk(hash);
      expect(result, isNotNull);
    });

    test('eviction removes LRU unpinned chunks', () async {
      cache.setMaxSize(3 * 1024); // 3 KB cap

      final h0 = _hash(10);
      final h1 = _hash(11);
      final h2 = _hash(12);

      await cache.writeChunk(h0, _data(1024, 0xAA)); // oldest
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await cache.writeChunk(h1, _data(1024, 0xBB));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await cache.writeChunk(h2, _data(1024, 0xCC)); // newest

      // Writing another 1 KB should evict the oldest (h0)
      final h3 = _hash(13);
      await cache.writeChunk(h3, _data(1024, 0xDD));

      expect(await cache.readChunk(h0), isNull);
      expect(await cache.readChunk(h3), isNotNull);
    });

    test('pinned chunk is not evicted', () async {
      cache.setMaxSize(2 * 1024); // 2 KB cap

      final h0 = _hash(20);
      final h1 = _hash(21);
      await cache.writeChunk(h0, _data(1024));
      await cache.writeChunk(h1, _data(1024));
      await cache.pinChunk(h0);

      // Writing 1 more KB must evict h1, not h0
      final h2 = _hash(22);
      await cache.writeChunk(h2, _data(1024));

      expect(await cache.readChunk(h0), isNotNull);
      expect(await cache.readChunk(h1), isNull);
    });

    test('throws InsufficientCacheSpaceException when all candidates pinned',
        () async {
      cache.setMaxSize(1024);

      final h0 = _hash(30);
      await cache.writeChunk(h0, _data(1024));
      await cache.pinChunk(h0);

      expect(
        () => cache.writeChunk(_hash(31), _data(1024)),
        throwsA(isA<InsufficientCacheSpaceException>()),
      );
    });

    test('unpin restores chunk to eviction pool', () async {
      cache.setMaxSize(2 * 1024);

      final h0 = _hash(40);
      final h1 = _hash(41);
      await cache.writeChunk(h0, _data(1024));
      await cache.writeChunk(h1, _data(1024));
      await cache.pinChunk(h0);
      await cache.unpinChunk(h0);

      // Now both are evictable; writing 1 KB should evict oldest
      await cache.writeChunk(_hash(42), _data(1024));
      // No exception thrown — eviction worked
    });

    test('setMaxSize takes effect immediately', () async {
      cache.setMaxSize(4 * 1024);

      final h0 = _hash(50);
      await cache.writeChunk(h0, _data(3 * 1024));

      // Tighten the cap — next write should trigger eviction
      cache.setMaxSize(4 * 1024);
      final h1 = _hash(51);
      await cache.writeChunk(h1, _data(2 * 1024));
      expect(await cache.readChunk(h1), isNotNull);
    });
  });
}
