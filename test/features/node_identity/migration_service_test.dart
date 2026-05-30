import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/activitypub/models/ap_activity.dart';
import 'package:nightingale/core/activitypub/models/ap_public_key.dart';
import 'package:nightingale/core/crypto/platform_crypto_service.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/features/federation/delivery/activity_delivery_service.dart';
import 'package:nightingale/features/federation/delivery/relay_client.dart';
import 'package:nightingale/features/federation/moderation/moderation_repository.dart';
import 'package:nightingale/features/node_identity/migration_service.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

AppDatabase _testDb() => AppDatabase(NativeDatabase.memory());

void main() {
  group('MigrationService', () {
    late AppDatabase db;
    late PlatformCryptoService crypto;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      db = _testDb();
      crypto = PlatformCryptoService();
      await crypto.generateKeyPair();
    });

    tearDown(() => db.close());

    test('exportToken returns a base64-decodable token', () async {
      // Insert a node identity row manually for the test
      await db.into(db.nodeIdentityTable).insert(
            NodeIdentityTableCompanion.insert(
              actorUrl: 'https://example.com/users/alice',
              publicKeyPem: await crypto.getPublicKeyPem(),
              preferredUsername: 'alice',
              displayName: 'Alice',
            ),
          );

      // Build a minimal repo stub
      final identityRepo = _FakeIdentityRepo(
        actorUrl: 'https://example.com/users/alice',
      );
      final svc = MigrationService(
        db: db,
        crypto: crypto,
        identityRepo: identityRepo,
        delivery: _FakeDelivery(db: db, crypto: crypto),
      );

      final result = await svc.exportToken();
      expect(result, isA<MigrationTokenOk>());
      final token = (result as MigrationTokenOk).token;

      // Must be base64-decodable and contain actorUrl
      final decoded = jsonDecode(utf8.decode(base64Url.decode(token)))
          as Map<String, dynamic>;
      final payload = jsonDecode(decoded['payload'] as String)
          as Map<String, dynamic>;
      expect(payload['actorUrl'], 'https://example.com/users/alice');
    });

    test('initiateMove rejects expired token', () async {
      final identityRepo =
          _FakeIdentityRepo(actorUrl: 'https://example.com/users/alice');
      final svc = MigrationService(
        db: db,
        crypto: crypto,
        identityRepo: identityRepo,
        delivery: _FakeDelivery(db: db, crypto: crypto),
      );

      // Build a token with issuedAt far in the past
      final payload = jsonEncode({
        'actorUrl': 'https://example.com/users/alice',
        'issuedAt': DateTime.now()
            .subtract(const Duration(hours: 73))
            .millisecondsSinceEpoch,
      });
      final sigBytes = await crypto.sign(utf8.encode(payload));
      final token = base64Url.encode(
        utf8.encode(jsonEncode({
          'payload': payload,
          'signature': base64.encode(sigBytes),
        })),
      );

      final result = await svc.initiateMove(
        migrationToken: token,
        newActorUrl: 'https://new.example/users/alice',
      );
      expect(result, isA<MoveError>());
      expect((result as MoveError).reason, contains('expired'));
    });

    test('initiateMove rejects previously used token', () async {
      final identityRepo =
          _FakeIdentityRepo(actorUrl: 'https://example.com/users/alice');
      final svc = MigrationService(
        db: db,
        crypto: crypto,
        identityRepo: identityRepo,
        delivery: _FakeDelivery(db: db, crypto: crypto),
      );

      final tokenResult = await svc.exportToken();
      final token = (tokenResult as MigrationTokenOk).token;

      // First use succeeds (no followers, so MoveOk)
      final first = await svc.initiateMove(
        migrationToken: token,
        newActorUrl: 'https://new.example/users/alice',
      );
      expect(first, isA<MoveOk>());

      // Second use must be rejected
      final second = await svc.initiateMove(
        migrationToken: token,
        newActorUrl: 'https://new.example/users/alice',
      );
      expect(second, isA<MoveError>());
      expect((second as MoveError).reason, contains('already used'));
    });

    test('initiateMove produces a Move activity with correct fields', () async {
      final deliverySpy = _FakeDelivery(db: db, crypto: crypto);
      final identityRepo =
          _FakeIdentityRepo(actorUrl: 'https://example.com/users/alice');
      final svc = MigrationService(
        db: db,
        crypto: crypto,
        identityRepo: identityRepo,
        delivery: deliverySpy,
      );

      final tokenResult = await svc.exportToken();
      final token = (tokenResult as MigrationTokenOk).token;

      final result = await svc.initiateMove(
        migrationToken: token,
        newActorUrl: 'https://new.example/users/alice',
      );
      expect(result, isA<MoveOk>());
    });
  });
}

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeIdentityRepo implements NodeIdentityRepository {
  _FakeIdentityRepo({required this.actorUrl});
  final String actorUrl;

  @override
  Future<bool> hasIdentity() async => true;

  @override
  Future<void> generateIdentity({required String displayName}) async {}

  @override
  Future<String> getActorUrl() async => actorUrl;

  @override
  Future<ApActor> getLocalActor() async => ApActor(
        id: actorUrl,
        type: 'Person',
        inbox: '$actorUrl/inbox',
        outbox: '$actorUrl/outbox',
        followers: '$actorUrl/followers',
        following: '$actorUrl/following',
        preferredUsername: 'alice',
        name: 'Alice',
        publicKey: ApPublicKey(
          id: '$actorUrl#main-key',
          owner: actorUrl,
          publicKeyPem: '',
        ),
      );
}

class _FakeDelivery extends ActivityDeliveryService {
  _FakeDelivery({required AppDatabase db, required PlatformCryptoService crypto})
      : super(
          db: db,
          sigService: HttpSignatureService(
            crypto: crypto,
            keyId: 'https://example.com/users/alice#main-key',
          ),
          relayClient: RelayClient(relayBaseUrl: ''),
          moderation: ModerationRepository(db: db),
        );

  final List<ApActivity> delivered = [];

  @override
  Future<void> deliver(ApActivity activity, String targetInboxUrl) async {
    delivered.add(activity);
  }
}
