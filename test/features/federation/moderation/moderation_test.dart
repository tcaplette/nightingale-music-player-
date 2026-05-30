import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/federation/moderation/moderation_repository.dart';
import 'package:nightingale/features/federation/moderation/rate_limiter.dart';

AppDatabase _testDb() => AppDatabase(NativeDatabase.memory());

void main() {
  group('ModerationRepository', () {
    late AppDatabase db;
    late ModerationRepository repo;

    setUp(() {
      db = _testDb();
      repo = ModerationRepository(db: db);
    });
    tearDown(() => db.close());

    test('defederate and isDefederated round-trip', () async {
      await repo.defederate('evil.example');
      expect(await repo.isDefederated('evil.example'), isTrue);
      expect(await repo.isDefederated('good.example'), isFalse);
    });

    test('removeDefederation lifts the block', () async {
      await repo.defederate('evil.example');
      await repo.removeDefederation('evil.example');
      expect(await repo.isDefederated('evil.example'), isFalse);
    });

    test('allow/deny list entries persist', () async {
      await repo.addToList('trusted.example', ListPolicy.allow);
      await repo.addToList('blocked.example', ListPolicy.deny);

      final allow = await repo.getAllowList();
      final deny = await repo.getDenyList();
      expect(allow.any((r) => r.domain == 'trusted.example'), isTrue);
      expect(deny.any((r) => r.domain == 'blocked.example'), isTrue);
    });
  });

  group('RateLimiter', () {
    test('allows requests within limit', () {
      final rl = RateLimiter(limit: 3, windowSeconds: 60);
      expect(rl.checkAndRecord('a.example'), isTrue);
      expect(rl.checkAndRecord('a.example'), isTrue);
      expect(rl.checkAndRecord('a.example'), isTrue);
    });

    test('blocks requests exceeding limit', () {
      final rl = RateLimiter(limit: 2, windowSeconds: 60);
      rl.checkAndRecord('a.example');
      rl.checkAndRecord('a.example');
      expect(rl.checkAndRecord('a.example'), isFalse);
    });

    test('different domains have independent windows', () {
      final rl = RateLimiter(limit: 1, windowSeconds: 60);
      rl.checkAndRecord('a.example');
      // a.example is now at limit, b.example should be fine
      expect(rl.checkAndRecord('b.example'), isTrue);
      expect(rl.checkAndRecord('a.example'), isFalse);
    });
  });
}
