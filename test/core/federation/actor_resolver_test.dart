import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  group('ActorResolver WebFinger handle detection', () {
    late AppDatabase db;

    setUp(() {
      db = _inMemoryDb();
    });

    tearDown(() => db.close());

    String _jrd(String actorUrl) => jsonEncode({
          'subject': 'acct:bob@192.168.1.50:7777',
          'links': [
            {'rel': 'self', 'type': 'application/activity+json', 'href': actorUrl},
          ],
        });

    test('handle with leading @ triggers WebFinger', () async {
      const actorUrl = 'http://192.168.1.50:7777/users/bob';
      final client = MockClient((request) async {
        if (request.url.path == '/.well-known/webfinger') {
          return http.Response(_jrd(actorUrl), 200);
        }
        if (request.url.path == '/users/bob') {
          return http.Response(jsonEncode(_actorJson(actorUrl)), 200);
        }
        return http.Response('not found', 404);
      });
      final resolver = ActorResolver(db: db, client: client);
      final result = await resolver.resolve('@bob@192.168.1.50:7777');
      expect(result, isA<ResolveOk>());
      expect((result as ResolveOk).actor.preferredUsername, 'bob');
    });

    test('handle without leading @ also triggers WebFinger', () async {
      const actorUrl = 'http://192.168.1.50:7777/users/bob';
      final client = MockClient((request) async {
        if (request.url.path == '/.well-known/webfinger') {
          return http.Response(_jrd(actorUrl), 200);
        }
        if (request.url.path == '/users/bob') {
          return http.Response(jsonEncode(_actorJson(actorUrl)), 200);
        }
        return http.Response('not found', 404);
      });
      final resolver = ActorResolver(db: db, client: client);
      final result = await resolver.resolve('bob@192.168.1.50:7777');
      expect(result, isA<ResolveOk>());
      expect((result as ResolveOk).actor.preferredUsername, 'bob');
    });

    test('http:// URL is not treated as a handle', () async {
      const actorUrl = 'http://192.168.1.50:7777/users/bob';
      final client = MockClient((request) async {
        if (request.url.path == '/users/bob') {
          return http.Response(jsonEncode(_actorJson(actorUrl)), 200);
        }
        // WebFinger should NOT be called for a full URL
        if (request.url.path == '/.well-known/webfinger') {
          return http.Response('should not be called', 500);
        }
        return http.Response('not found', 404);
      });
      final resolver = ActorResolver(db: db, client: client);
      final result = await resolver.resolve(actorUrl);
      expect(result, isA<ResolveOk>());
    });

    test('HTTPS WebFinger fails then HTTP fallback succeeds', () async {
      const actorUrl = 'http://192.168.1.50:7777/users/bob';
      final client = MockClient((request) async {
        if (request.url.scheme == 'https' &&
            request.url.path == '/.well-known/webfinger') {
          return http.Response('not found', 404);
        }
        if (request.url.scheme == 'http' &&
            request.url.path == '/.well-known/webfinger') {
          return http.Response(_jrd(actorUrl), 200);
        }
        if (request.url.path == '/users/bob') {
          return http.Response(jsonEncode(_actorJson(actorUrl)), 200);
        }
        return http.Response('not found', 404);
      });
      final resolver = ActorResolver(db: db, client: client);
      final result = await resolver.resolve('@bob@192.168.1.50:7777');
      expect(result, isA<ResolveOk>());
    });

    test('both HTTPS and HTTP WebFinger fail returns ResolveFailed', () async {
      final client = MockClient((_) async => http.Response('nope', 404));
      final resolver = ActorResolver(db: db, client: client);
      final result = await resolver.resolve('@bob@192.168.1.50:7777');
      expect(result, isA<ResolveFailed>());
    });
  });
}
