import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/activitypub/models/ap_activity.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/activitypub/models/ap_public_key.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/features/federation/delivery/activity_delivery_service.dart';
import 'package:nightingale/features/federation/discovery/peer_exchange_service.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';
import 'package:nightingale/features/federation/social/social_subscribing_service.dart';

AppDatabase _testDb() => AppDatabase(NativeDatabase.memory());

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeActorResolver implements ActorResolver {
  final Map<String, ApActor> _actors = {};
  void register(ApActor actor) => _actors[actor.id] = actor;

  @override
  Future<ResolveResult> resolve(
    String handleOrUrl, {
    String discoverySource = 'manual',
  }) async {
    final actor = _actors[handleOrUrl];
    if (actor != null) return ResolveOk(actor);
    return ResolveFailed('not found: $handleOrUrl');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SpyPeerExchangeService implements PeerExchangeService {
  final List<String> enqueuedUrls = [];

  @override
  void enqueue(String actorUrl) {
    enqueuedUrls.add(actorUrl);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDelivery implements ActivityDeliveryService {
  final List<({ApActivity activity, String inbox})> delivered = [];

  @override
  Future<void> deliver(ApActivity activity, String targetInboxUrl) async {
    delivered.add((activity: activity, inbox: targetInboxUrl));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeIdentityRepo implements NodeIdentityRepository {
  @override
  Future<String> getActorUrl() async => 'https://local.example/users/me';

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
      name: 'Test User',
      publicKey: ApPublicKey(
        id: '$id#main-key',
        owner: id,
        publicKeyPem: '-----BEGIN PUBLIC KEY-----\nfake\n-----END PUBLIC KEY-----',
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('SocialSubscribingService', () {
    late AppDatabase db;
    late _FakeActorResolver resolver;
    late _SpyPeerExchangeService peerExchange;
    late _FakeDelivery delivery;
    late SocialSubscribingService svc;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      db = _testDb();
      resolver = _FakeActorResolver();
      peerExchange = _SpyPeerExchangeService();
      delivery = _FakeDelivery();
      svc = SocialSubscribingService(
        db: db,
        actorResolver: resolver,
        delivery: delivery,
        identityRepo: _FakeIdentityRepo(),
        peerExchange: peerExchange,
      );
    });

    tearDown(() => db.close());

    test('followActor enqueues a peer exchange job', () async {
      final actorUrl = 'https://remote.example/users/alice';
      resolver.register(_makeActor(actorUrl));

      await svc.followActor(actorUrl);

      expect(peerExchange.enqueuedUrls, contains(actorUrl));
    });

    test('followActor sends a Follow activity to the target inbox', () async {
      final actorUrl = 'https://remote.example/users/alice';
      resolver.register(_makeActor(actorUrl));

      await svc.followActor(actorUrl);

      expect(delivery.delivered, hasLength(1));
      expect(delivery.delivered.first.inbox, '$actorUrl/inbox');
      expect(delivery.delivered.first.activity, isA<ApFollow>());
    });

    test('followActor is idempotent — does not re-enqueue if already following', () async {
      final actorUrl = 'https://remote.example/users/alice';
      resolver.register(_makeActor(actorUrl));

      await svc.followActor(actorUrl);
      await svc.followActor(actorUrl); // second call

      // Peer exchange should only be triggered once.
      expect(peerExchange.enqueuedUrls.where((u) => u == actorUrl), hasLength(1));
    });

    test('unfollowActor does NOT enqueue a peer exchange job', () async {
      final actorUrl = 'https://remote.example/users/alice';
      resolver.register(_makeActor(actorUrl));

      // Follow first so the DB row exists
      await svc.followActor(actorUrl);
      final countBefore = peerExchange.enqueuedUrls.length;

      await svc.unfollowActor(actorUrl);

      // No additional enqueue from unfollow
      expect(peerExchange.enqueuedUrls.length, countBefore);
    });
  });
}
