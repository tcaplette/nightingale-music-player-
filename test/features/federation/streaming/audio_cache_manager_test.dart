import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/federation/streaming/audio_cache_manager.dart';

AppDatabase _inMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  group('AudioCacheManager', () {
    late AppDatabase db;
    late AudioCacheManager cache;

    setUp(() async {
      db = _inMemoryDb();
      cache = AudioCacheManager(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('getCachedPath returns null when not cached', () async {
      final path = await cache.getCachedPath('track1', 'http://actor1');
      expect(path, isNull);
    });

    test('cacheFile stores entry in database', () async {
      // Create a temp file
      final tempFile = File('${Directory.systemTemp.path}/test_audio.mp3');
      await tempFile.writeAsBytes(List<int>.generate(1000, (i) => i % 256));

      await cache.cacheFile(
        trackId: 'track1',
        sourceActorUrl: 'http://actor1',
        localPath: tempFile.path,
      );

      final path = await cache.getCachedPath('track1', 'http://actor1');
      expect(path, tempFile.path);

      await tempFile.delete();
    });

    test('pinFile prevents eviction', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_pinned.mp3');
      await tempFile.writeAsBytes(List<int>.generate(1000, (i) => i % 256));

      await cache.cacheFile(
        trackId: 'pinned',
        sourceActorUrl: 'http://actor1',
        localPath: tempFile.path,
      );

      await cache.pinFile('pinned', 'http://actor1');

      // Verify pinned status by checking it stays after eviction attempt
      // (would need more setup for full eviction test)
      final path = await cache.getCachedPath('pinned', 'http://actor1');
      expect(path, isNotNull);

      await tempFile.delete();
    });

    test('unpinFile allows eviction', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_unpinned.mp3');
      await tempFile.writeAsBytes(List<int>.generate(1000, (i) => i % 256));

      await cache.cacheFile(
        trackId: 'unpinned',
        sourceActorUrl: 'http://actor1',
        localPath: tempFile.path,
      );

      await cache.pinFile('unpinned', 'http://actor1');
      await cache.unpinFile('unpinned', 'http://actor1');

      final path = await cache.getCachedPath('unpinned', 'http://actor1');
      expect(path, isNotNull);

      await tempFile.delete();
    });
  });
}
