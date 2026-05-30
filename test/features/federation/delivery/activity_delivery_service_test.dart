import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/activitypub/models/ap_activity.dart';
import 'package:nightingale/core/crypto/platform_crypto_service.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/features/federation/delivery/activity_delivery_service.dart';
import 'package:nightingale/features/federation/delivery/relay_client.dart';
import 'package:nightingale/features/federation/moderation/moderation_repository.dart';

AppDatabase _testDb() => AppDatabase(NativeDatabase.memory());

class _FakeRelay extends RelayClient {
  _FakeRelay() : super(relayBaseUrl: '');
  String? lastTarget;

  @override
  Future<String?> handOff(ApActivity activity, String targetActorUrl) async {
    lastTarget = targetActorUrl;
    return 'fake-ref-123';
  }
}

void main() {
  group('ActivityDeliveryService', () {
    late AppDatabase db;
    late _FakeRelay relay;
    late ActivityDeliveryService svc;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      db = _testDb();
      relay = _FakeRelay();
      final crypto = PlatformCryptoService();
      await crypto.generateKeyPair();
      final sig = HttpSignatureService(
        crypto: crypto,
        keyId: 'https://example.com/users/alice#main-key',
      );
      final mod = ModerationRepository(db: db);
      svc = ActivityDeliveryService(
        db: db,
        sigService: sig,
        relayClient: relay,
        moderation: mod,
      );
    });

    tearDown(() => db.close());

    test('startup sweep re-enqueues pending entries', () async {
      // Insert a stale pending activity directly
      final activity = ApFollow(
        id: 'https://example.com/activities/test1',
        actor: 'https://example.com/users/alice',
        object: 'https://b.example/users/bob',
      );
      await db.into(db.outboxActivitiesTable).insert(
            OutboxActivitiesTableCompanion.insert(
              activityId: activity.id,
              type: activity.type,
              targetInboxUrl: 'https://b.example/users/bob/inbox',
              payloadJson: jsonEncode(activity.toJson()),
              status: const Value('pending'),
            ),
          );

      // sweep should not throw
      await expectLater(svc.sweepPendingOnStartup(), completes);
    });

    test('defederated target is suppressed before queueing', () async {
      final mod = ModerationRepository(db: db);
      await mod.defederate('evil.example');

      final activity = ApFollow(
        id: 'https://example.com/activities/test2',
        actor: 'https://example.com/users/alice',
        object: 'https://evil.example/users/bob',
      );
      await svc.deliver(activity, 'https://evil.example/users/bob/inbox');

      final queued = await db.select(db.outboxActivitiesTable).get();
      expect(queued.where((r) => r.activityId == activity.id), isEmpty);
    });
  });
}
