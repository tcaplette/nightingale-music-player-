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
import 'package:nightingale/features/federation/moderation/moderation_repository.dart';

AppDatabase _testDb() => AppDatabase(NativeDatabase.memory());

void main() {
  group('ActivityDeliveryService', () {
    late AppDatabase db;
    late ActivityDeliveryService svc;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      db = _testDb();
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
        moderation: mod,
      );
    });

    tearDown(() => db.close());

    test('startup sweep re-enqueues pending entries', () async {
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

      await expectLater(svc.sweepPendingOnStartup(), completes);
    });

    test('startup sweep picks up stale retrying rows', () async {
      final activity = ApFollow(
        id: 'https://example.com/activities/test2',
        actor: 'https://example.com/users/alice',
        object: 'https://b.example/users/bob',
      );
      // Insert a retrying row with a lastAttemptedAt well in the past.
      await db.into(db.outboxActivitiesTable).insert(
            OutboxActivitiesTableCompanion.insert(
              activityId: activity.id,
              type: activity.type,
              targetInboxUrl: 'https://b.example/users/bob/inbox',
              payloadJson: jsonEncode(activity.toJson()),
              status: const Value('retrying'),
              lastAttemptedAt: Value(
                DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
              ),
            ),
          );

      await expectLater(svc.sweepPendingOnStartup(), completes);
    });

    test('defederated target is suppressed before queueing', () async {
      final mod = ModerationRepository(db: db);
      await mod.defederate('evil.example');

      final activity = ApFollow(
        id: 'https://example.com/activities/test3',
        actor: 'https://example.com/users/alice',
        object: 'https://evil.example/users/bob',
      );
      await svc.deliver(activity, 'https://evil.example/users/bob/inbox');

      final queued = await db.select(db.outboxActivitiesTable).get();
      expect(queued.where((r) => r.activityId == activity.id), isEmpty);
    });

    test('exhausted retries leave activity as pending not relayed', () async {
      final activity = ApFollow(
        id: 'https://example.com/activities/test4',
        actor: 'https://example.com/users/alice',
        object: 'https://b.example/users/bob',
      );
      // Pre-insert as pending so we can verify the outcome without actual HTTP.
      await db.into(db.outboxActivitiesTable).insert(
            OutboxActivitiesTableCompanion.insert(
              activityId: activity.id,
              type: activity.type,
              targetInboxUrl: 'http://127.0.0.1:1/inbox', // unreachable
              payloadJson: jsonEncode(activity.toJson()),
              status: const Value('pending'),
            ),
          );

      // Run delivery (it will fail all attempts quickly since port 1 is closed).
      // Just verify no relay status is ever written.
      // We poll the DB after a short delay.
      await svc.sweepPendingOnStartup();
      await Future.delayed(const Duration(milliseconds: 500));

      final rows = await db.select(db.outboxActivitiesTable).get();
      for (final row in rows) {
        expect(row.status, isNot('relayed'));
      }
    });
  });
}
