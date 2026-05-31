import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/activitypub/models/ap_public_key.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/features/federation/reachability/node_reachability_service.dart';
import 'package:nightingale/features/federation/streaming/audio_cache_manager.dart';
import 'package:nightingale/features/federation/streaming/stream_resolver.dart';

class _FakeActorResolver implements ActorResolver {
  @override
  Future<ResolveResult> resolve(String handleOrUrl, {String discoverySource = 'manual'}) async {
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
        publicKeyPem: '-----BEGIN PUBLIC KEY-----\nMCowBQYDK2VwAyEA\n-----END PUBLIC KEY-----',
      ),
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCacheManager implements AudioCacheManager {
  @override
  Future<String?> getCachedPath(String trackId, String sourceActorUrl) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReachability implements NodeReachabilityService {
  bool _reachable = true;

  void setReachable(bool value) => _reachable = value;

  @override
  Future<bool> isReachable(String actorOrNodeUrl, {String? publicAddress}) async =>
      _reachable;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('StreamResolver', () {
    late StreamResolver resolver;
    late _FakeReachability reachability;

    setUp(() {
      reachability = _FakeReachability();
      resolver = StreamResolver(
        actorResolver: _FakeActorResolver(),
        reachability: reachability,
        cacheManager: _FakeCacheManager(),
      );
    });

    test('returns direct path when actor is reachable', () async {
      reachability.setReachable(true);
      final result = await resolver.resolveRemoteTrack(
        actorUrl: 'http://actor1/users/test',
        trackId: '123',
      );
      expect(result.path, StreamPath.direct);
      expect(result.url, 'http://actor1/stream/123');
    });

    test('returns unavailable when actor is unreachable and no cache', () async {
      reachability.setReachable(false);
      final result = await resolver.resolveRemoteTrack(
        actorUrl: 'http://actor1/users/test',
        trackId: '123',
      );
      expect(result.path, StreamPath.unavailable);
      expect(result.error, isNotNull);
    });
  });
}
