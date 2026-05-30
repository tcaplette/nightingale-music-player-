import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';

// Minimal actor JSON for test fixtures
Map<String, dynamic> _actorJson(String url) => {
      '@context': ['https://www.w3.org/ns/activitystreams'],
      'id': url,
      'type': 'Person',
      'inbox': '$url/inbox',
      'outbox': '$url/outbox',
      'followers': '$url/followers',
      'following': '$url/following',
      'preferredUsername': 'bob',
      'name': 'Bob',
      'publicKey': {
        'id': '$url#main-key',
        'owner': url,
        'publicKeyPem': '-----BEGIN PUBLIC KEY-----\nABC\n-----END PUBLIC KEY-----\n',
      },
    };

AppDatabase _inMemoryDb() =>
    AppDatabase(NativeDatabase.memory());

void main() {
  group('ActorResolver cache', () {
    late AppDatabase db;
    late ActorResolver resolver;

    setUp(() {
      db = _inMemoryDb();
      resolver = ActorResolver(db: db);
    });

    tearDown(() => db.close());

    test('cache miss then hit', () async {
      const url = 'https://b.example/users/bob';
      final json = _actorJson(url);

      // Pre-populate cache to simulate a prior network fetch
      await db.into(db.actorCacheTable).insert(
            ActorCacheTableCompanion.insert(
              actorUrl: url,
              actorJson: jsonEncode(json),
              ttlSeconds: const Value(900),
            ),
          );

      final result = await resolver.resolve(url);
      expect(result, isA<ResolveOk>());
      expect((result as ResolveOk).actor.preferredUsername, 'bob');
    });

    test('expired cache entry triggers re-fetch path (returns ResolveFailed without network)', () async {
      const url = 'https://b.example/users/bob';
      final json = _actorJson(url);

      // Insert with ttlSeconds = 0 so it's immediately expired
      await db.into(db.actorCacheTable).insert(
            ActorCacheTableCompanion(
              actorUrl: Value(url),
              actorJson: Value(jsonEncode(json)),
              ttlSeconds: const Value(0),
              cachedAt: Value(
                DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
              ),
            ),
          );

      // No real network available in test, so should get ResolveFailed
      final result = await resolver.resolve(url);
      expect(result, isA<ResolveFailed>());
    });

    test('invalidate removes cache entry', () async {
      const url = 'https://b.example/users/bob';
      await db.into(db.actorCacheTable).insert(
            ActorCacheTableCompanion.insert(
              actorUrl: url,
              actorJson: jsonEncode(_actorJson(url)),
            ),
          );

      await resolver.invalidate(url);
      final entries = await resolver.getCacheEntries();
      expect(entries.where((e) => e.actorUrl == url), isEmpty);
    });
  });
}
