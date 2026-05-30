import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/crypto/crypto_service.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/core/resilience/activity_queue_service.dart';

// Minimal stub CryptoService for signing
class _StubCrypto implements CryptoService {
  @override
  Future<bool> hasKeyPair() async => true;
  @override
  Future<void> generateKeyPair() async {}
  @override
  Future<List<int>> sign(List<int> message) async => List.filled(64, 0);
  @override
  Future<String> getPublicKeyPem() async => '-----BEGIN PUBLIC KEY-----\nfake\n-----END PUBLIC KEY-----\n';
}

void main() {
  late AppDatabase db;
  late ActivityQueueService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final sigService = HttpSignatureService(
      crypto: _StubCrypto(),
      keyId: 'https://node.example/users/node#main-key',
    );
    service = ActivityQueueService(db: db, sigService: sigService);
  });

  tearDown(() async => db.close());

  test('enqueue writes a pending activity to the database', () async {
    await service.enqueue(
      activityJson: '{"type":"Like"}',
      activityType: 'Like',
      targetActorUrl: 'https://other.node/inbox',
    );

    final rows = await db.select(db.activityQueueTable).get();
    expect(rows.length, 1);
    expect(rows.first.status, 'pending');
    expect(rows.first.activityType, 'Like');
    expect(rows.first.targetActorUrl, 'https://other.node/inbox');
  });

  test('enqueue stores multiple activities in FIFO order by createdAt', () async {
    await service.enqueue(
      activityJson: '{"type":"Listen"}',
      activityType: 'Listen',
      targetActorUrl: 'https://other.node/inbox',
    );
    await service.enqueue(
      activityJson: '{"type":"Announce"}',
      activityType: 'Announce',
      targetActorUrl: 'https://other.node/inbox',
    );

    final rows = await db.select(db.activityQueueTable).get();
    expect(rows.length, 2);
    expect(rows.first.activityType, 'Listen');
    expect(rows.last.activityType, 'Announce');
  });
}
