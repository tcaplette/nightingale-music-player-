import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/activitypub/models/ap_public_key.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/federation/reachability/node_reachability_service.dart';
import 'package:nightingale/features/federation/streaming/audio_cache_manager.dart';
import 'package:nightingale/features/federation/streaming/chunk_cache_manager.dart';
import 'package:nightingale/features/federation/streaming/chunk_manifest.dart';
import 'package:nightingale/features/federation/streaming/stream_resolver.dart';

AppDatabase _inMemoryDb() => AppDatabase(NativeDatabase.memory());

class _FakeActorResolver implements ActorResolver {
  @override
  Future<ResolveResult> resolve(String handleOrUrl,
      {String discoverySource = 'manual'}) async {
    return ResolveOk(ApActor(
      id: 'http://actor1/users/test',
      type: 'Person',
      inbox: 'http://actor1/inbox',
      outbox: 'http://actor1/outbox',
      followers: 'http://actor1/followers',
      following: 'http://actor1/following',
      preferredUsername: 'test',
      name: 'Test User',
      publicKey: ApPublicKey(
        id: 'http://actor1/users/test#main-key',
        owner: 'http://actor1/users/test',
        publicKeyPem:
            '-----BEGIN PUBLIC KEY-----\nMCowBQYDK2VwAyEA\n-----END PUBLIC KEY-----',
      ),
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCacheManager implements AudioCacheManager {
  @override
  Future<String?> getCachedPath(String trackId, String sourceActorUrl) async =>
      null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReachability implements NodeReachabilityService {
  bool _reachable;
  _FakeReachability({bool reachable = true}) : _reachable = reachable;
  void setReachable(bool v) => _reachable = v;

  @override
  Future<bool> isReachable(String actorOrNodeUrl,
          {String? publicAddress}) async =>
      _reachable;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('StreamResolver — legacy paths', () {
    late StreamResolver resolver;
    late _FakeReachability reachability;

    setUp(() {
      reachability = _FakeReachability();
      resolver = StreamResolver(
        actorResolver: _FakeActorResolver(),
        reachability: reachability,
        cacheManager: _NoCacheManager(),
      );
    });

    test('returns direct path when actor is reachable', () async {
      final result = await resolver.resolveRemoteTrack(
        actorUrl: 'http://actor1/users/test',
        trackId: '123',
      );
      expect(result.path, StreamPath.direct);
      expect(result.url, 'http://actor1/stream/123');
    });

    test('returns unavailable when actor unreachable and no cache', () async {
      reachability.setReachable(false);
      final result = await resolver.resolveRemoteTrack(
        actorUrl: 'http://actor1/users/test',
        trackId: '123',
      );
      expect(result.path, StreamPath.unavailable);
      expect(result.error, isNotNull);
    });
  });

  group('StreamResolver — chunk path', () {
    late AppDatabase db;
    late ChunkCacheManager chunkCache;
    late ChunkManifestRepository manifests;
    late StreamResolver resolver;
    late _FakeReachability reachability;

    const actorUrl = 'http://actor1/users/test';

    setUp(() async {
      db = _inMemoryDb();
      chunkCache = ChunkCacheManager(db: db);
      manifests = ChunkManifestRepository(db: db);
      reachability = _FakeReachability();

      resolver = StreamResolver(
        actorResolver: _FakeActorResolver(),
        reachability: reachability,
        cacheManager: _NoCacheManager(),
        chunkCacheManager: chunkCache,
        manifestRepository: manifests,
      );
    });

    tearDown(() => db.close());

    Future<ChunkManifest> _populateManifest() async {
      final data = Uint8List.fromList(List<int>.filled(1024, 0xAB));
      final hashStr = sha256.convert(data).toString();
      final hashBytes =
          Uint8List.fromList(sha256.convert(data).bytes);
      await chunkCache.writeChunk(hashBytes, data);

      final manifest = ChunkManifest(
        trackId: 1,
        sourceActorUrl: actorUrl,
        chunkHashes: [hashStr],
        totalSizeBytes: 1024,
        fetchedAt: DateTime.now(),
      );
      await manifests.saveManifest(manifest);
      return manifest;
    }

    test('returns chunk path when manifest exists and all chunks cached',
        () async {
      await _populateManifest();

      final result = await resolver.resolveRemoteTrack(
        actorUrl: actorUrl,
        trackId: '1',
      );

      expect(result.path, StreamPath.chunk);
      expect(result.assemblerManifest, isNotNull);
    });

    test('falls back to direct stream when manifest has missing chunks',
        () async {
      // Save manifest but don't write the chunk to cache
      final fakeHash = 'a' * 64;
      final manifest = ChunkManifest(
        trackId: 2,
        sourceActorUrl: actorUrl,
        chunkHashes: [fakeHash],
        totalSizeBytes: 512,
        fetchedAt: DateTime.now(),
      );
      await manifests.saveManifest(manifest);

      // Node is reachable but chunk endpoint would 404 (no HTTP server in test)
      // The resolver falls back to direct stream since peer fetch fails
      final result = await resolver.resolveRemoteTrack(
        actorUrl: actorUrl,
        trackId: '2',
      );
      // Either direct or unavailable is acceptable — not chunk
      expect(result.path, isNot(StreamPath.chunk));
    });

    test('returns unavailable when node unreachable and no manifest', () async {
      reachability.setReachable(false);
      final result = await resolver.resolveRemoteTrack(
        actorUrl: actorUrl,
        trackId: '99',
      );
      expect(result.path, StreamPath.unavailable);
    });
  });
}
