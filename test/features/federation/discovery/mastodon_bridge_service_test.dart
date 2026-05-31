import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/activitypub/models/ap_public_key.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/features/federation/discovery/mastodon_bridge_service.dart';

// Minimal valid actor JSON for Mastodon-style actors.
Map<String, dynamic> _mastodonActorJson({
  required String id,
  String? nightingaleUrl,
}) =>
    {
      'id': id,
      'type': 'Person',
      'inbox': '$id/inbox',
      'outbox': '$id/outbox',
      'followers': '$id/followers',
      'following': '$id/following',
      'preferredUsername': id.split('/').last,
      'name': 'Test User',
      'publicKey': {
        'id': '$id#main-key',
        'owner': id,
        'publicKeyPem': '-----BEGIN PUBLIC KEY-----\nfake\n-----END PUBLIC KEY-----',
      },
      if (nightingaleUrl != null) 'x-nightingale-actor-url': nightingaleUrl,
    };

Map<String, dynamic> _collectionJson(String id, List<dynamic> items) => {
      'id': id,
      'type': 'OrderedCollection',
      'totalItems': items.length,
      'orderedItems': items,
    };

class _FakeActorResolver implements ActorResolver {
  final Map<String, ApActor> _actors = {};
  final List<String> resolvedUrls = [];

  void registerActor(ApActor actor) => _actors[actor.id] = actor;

  /// Also register under a WebFinger handle so tests can call with @user@host.
  void registerHandle(String handle, ApActor actor) {
    _actors[handle] = actor;
    _actors[actor.id] = actor;
  }

  @override
  Future<ResolveResult> resolve(
    String handleOrUrl, {
    String discoverySource = 'manual',
  }) async {
    resolvedUrls.add(handleOrUrl);
    final actor = _actors[handleOrUrl];
    if (actor != null) return ResolveOk(actor);
    return ResolveFailed('not found: $handleOrUrl');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ApActor _makeActor(String id) => ApActor(
      id: id,
      type: 'Person',
      inbox: '$id/inbox',
      outbox: '$id/outbox',
      followers: '$id/followers',
      following: '$id/following',
      preferredUsername: id.split('/').last,
      name: 'User ${id.split('/').last}',
      publicKey: ApPublicKey(
        id: '$id#main-key',
        owner: id,
        publicKeyPem: '-----BEGIN PUBLIC KEY-----\nfake\n-----END PUBLIC KEY-----',
      ),
    );

void main() {
  group('MastodonBridgeService.validateHandle', () {
    test('accepts @user@instance format', () {
      expect(MastodonBridgeService.validateHandle('@howard@mastodon.social'), isNull);
    });

    test('accepts user@instance without leading @', () {
      expect(MastodonBridgeService.validateHandle('howard@mastodon.social'), isNull);
    });

    test('rejects plain username with no domain', () {
      expect(
        MastodonBridgeService.validateHandle('howard'),
        isNotNull,
      );
    });

    test('rejects empty string', () {
      expect(MastodonBridgeService.validateHandle(''), isNotNull);
    });

    test('rejects @-only', () {
      expect(MastodonBridgeService.validateHandle('@'), isNotNull);
    });
  });

  group('MastodonBridgeService.parseInstance', () {
    test('extracts instance from @user@instance', () {
      expect(
        MastodonBridgeService.parseInstance('@howard@mastodon.social'),
        'mastodon.social',
      );
    });

    test('returns null for malformed handle', () {
      expect(MastodonBridgeService.parseInstance('notahandle'), isNull);
    });
  });

  group('MastodonBridgeService — rate limiting', () {
    test('is not rate-limited on first call', () {
      final bridge = MastodonBridgeService(
        actorResolver: _FakeActorResolver(),
      );
      expect(bridge.isRateLimited('mastodon.social'), isFalse);
    });
  });

  group('MastodonBridgeService.importSocialGraph', () {
    test('returns empty list when Mastodon actor cannot be resolved', () async {
      final resolver = _FakeActorResolver(); // No actors registered
      final bridge = MastodonBridgeService(
        actorResolver: resolver,
        client: MockClient((_) async => http.Response('', 404)),
      );

      final result = await bridge.importSocialGraph('@nobody@mastodon.social');
      expect(result, isEmpty);
    });

    test('extracts Nightingale actors via x-nightingale-actor-url', () async {
      final mastodonActorUrl = 'https://mastodon.social/users/howard';
      final nightingaleActorUrl = 'https://nightingale.example/users/howard';
      final followerActorUrl = 'https://mastodon.social/users/friend';

      // The Mastodon actor for the user being imported
      final mastodonActor = _makeActor(mastodonActorUrl)..toJson();

      // A follower who has the Nightingale extension field
      final followerJson = _mastodonActorJson(
        id: followerActorUrl,
        nightingaleUrl: nightingaleActorUrl,
      );

      // Followers collection contains the follower inline as a full object
      final followersCollectionUrl = '$mastodonActorUrl/followers';
      final followingCollectionUrl = '$mastodonActorUrl/following';

      final resolver = _FakeActorResolver();
      resolver.registerActor(_makeActor(nightingaleActorUrl));

      final client = MockClient((request) async {
        final url = request.url.toString();
        if (url == followersCollectionUrl) {
          return http.Response(
            jsonEncode(_collectionJson(followersCollectionUrl, [followerJson])),
            200,
            headers: {'content-type': 'application/activity+json'},
          );
        }
        if (url == followingCollectionUrl) {
          return http.Response(
            jsonEncode(_collectionJson(followingCollectionUrl, [])),
            200,
            headers: {'content-type': 'application/activity+json'},
          );
        }
        return http.Response('', 404);
      });

      final bridge = MastodonBridgeService(
        actorResolver: resolver,
        client: client,
      );

      // Register the Mastodon actor under BOTH its URL and the WebFinger handle
      final mastodonActorWithCollections = ApActor(
        id: mastodonActorUrl,
        type: 'Person',
        inbox: '$mastodonActorUrl/inbox',
        outbox: '$mastodonActorUrl/outbox',
        followers: followersCollectionUrl,
        following: followingCollectionUrl,
        preferredUsername: 'howard',
        name: 'Howard',
        publicKey: ApPublicKey(
          id: '$mastodonActorUrl#main-key',
          owner: mastodonActorUrl,
          publicKeyPem: '-----BEGIN PUBLIC KEY-----\nfake\n-----END PUBLIC KEY-----',
        ),
      );
      resolver.registerHandle('@howard@mastodon.social', mastodonActorWithCollections);

      final matches = await bridge.importSocialGraph('@howard@mastodon.social');

      expect(matches, hasLength(1));
      expect(matches.first.actorUrl, nightingaleActorUrl);
    });

    test('deduplicates contacts appearing in both followers and following', () async {
      final mastodonActorUrl = 'https://mastodon.social/users/howard';
      final nightingaleActorUrl = 'https://nightingale.example/users/shared';
      final sharedFriendJson = _mastodonActorJson(
        id: 'https://mastodon.social/users/shared',
        nightingaleUrl: nightingaleActorUrl,
      );

      final resolver = _FakeActorResolver();
      final mastodonActor = ApActor(
        id: mastodonActorUrl,
        type: 'Person',
        inbox: '$mastodonActorUrl/inbox',
        outbox: '$mastodonActorUrl/outbox',
        followers: '$mastodonActorUrl/followers',
        following: '$mastodonActorUrl/following',
        preferredUsername: 'howard',
        name: 'Howard',
        publicKey: ApPublicKey(
          id: '$mastodonActorUrl#main-key',
          owner: mastodonActorUrl,
          publicKeyPem: '-----BEGIN PUBLIC KEY-----\nfake\n-----END PUBLIC KEY-----',
        ),
      );
      resolver.registerHandle('@howard@mastodon.social', mastodonActor);
      resolver.registerActor(_makeActor(nightingaleActorUrl));

      final client = MockClient((request) async {
        // Return the same friend in both followers and following
        return http.Response(
          jsonEncode(
            _collectionJson(request.url.toString(), [sharedFriendJson]),
          ),
          200,
          headers: {'content-type': 'application/activity+json'},
        );
      });

      final bridge = MastodonBridgeService(
        actorResolver: resolver,
        client: client,
      );

      final matches = await bridge.importSocialGraph('@howard@mastodon.social');
      expect(matches, hasLength(1));
    });

    test('ignores actors with malformed x-nightingale-actor-url', () async {
      final mastodonActorUrl = 'https://mastodon.social/users/howard';
      final badActorJson = _mastodonActorJson(
        id: 'https://mastodon.social/users/friend',
        nightingaleUrl: 'not-a-url',
      );

      final resolver = _FakeActorResolver();
      final mastodonActor = ApActor(
        id: mastodonActorUrl,
        type: 'Person',
        inbox: '$mastodonActorUrl/inbox',
        outbox: '$mastodonActorUrl/outbox',
        followers: '$mastodonActorUrl/followers',
        following: '$mastodonActorUrl/following',
        preferredUsername: 'howard',
        name: 'Howard',
        publicKey: ApPublicKey(
          id: '$mastodonActorUrl#main-key',
          owner: mastodonActorUrl,
          publicKeyPem: '-----BEGIN PUBLIC KEY-----\nfake\n-----END PUBLIC KEY-----',
        ),
      );
      resolver.registerHandle('@howard@mastodon.social', mastodonActor);

      final client = MockClient((request) async => http.Response(
            jsonEncode(_collectionJson(request.url.toString(), [badActorJson])),
            200,
            headers: {'content-type': 'application/activity+json'},
          ));

      final bridge = MastodonBridgeService(
        actorResolver: resolver,
        client: client,
      );

      final matches = await bridge.importSocialGraph('@howard@mastodon.social');
      expect(matches, isEmpty);
    });

    test('handles 403 on followers collection gracefully', () async {
      final mastodonActorUrl = 'https://mastodon.social/users/private';
      final resolver = _FakeActorResolver();
      final mastodonActor = ApActor(
        id: mastodonActorUrl,
        type: 'Person',
        inbox: '$mastodonActorUrl/inbox',
        outbox: '$mastodonActorUrl/outbox',
        followers: '$mastodonActorUrl/followers',
        following: '$mastodonActorUrl/following',
        preferredUsername: 'private',
        name: 'Private User',
        publicKey: ApPublicKey(
          id: '$mastodonActorUrl#main-key',
          owner: mastodonActorUrl,
          publicKeyPem: '-----BEGIN PUBLIC KEY-----\nfake\n-----END PUBLIC KEY-----',
        ),
      );
      resolver.registerHandle('@private@mastodon.social', mastodonActor);

      final client = MockClient((_) async => http.Response('Forbidden', 403));

      final bridge = MastodonBridgeService(
        actorResolver: resolver,
        client: client,
      );

      // Should not throw — just return empty
      final matches = await bridge.importSocialGraph('@private@mastodon.social');
      expect(matches, isEmpty);
    });
  });
}
