import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/activitypub/models/ap_activity.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/activitypub/models/ap_collection.dart';
import 'package:nightingale/core/activitypub/models/ap_public_key.dart';
import 'package:nightingale/core/activitypub/models/webfinger_jrd.dart';

void main() {
  group('ApActor', () {
    test('round-trips through fromJson/toJson', () {
      final json = {
        '@context': ['https://www.w3.org/ns/activitystreams'],
        'id': 'https://node.example/users/alice',
        'type': 'Person',
        'inbox': 'https://node.example/users/alice/inbox',
        'outbox': 'https://node.example/users/alice/outbox',
        'followers': 'https://node.example/users/alice/followers',
        'following': 'https://node.example/users/alice/following',
        'preferredUsername': 'alice',
        'name': 'Alice',
        'publicKey': {
          'id': 'https://node.example/users/alice#main-key',
          'owner': 'https://node.example/users/alice',
          'publicKeyPem': '-----BEGIN PUBLIC KEY-----\nABC\n-----END PUBLIC KEY-----\n',
        },
      };
      final actor = ApActor.fromJson(json);
      expect(actor.id, 'https://node.example/users/alice');
      expect(actor.preferredUsername, 'alice');
      expect(actor.publicKey.publicKeyPem, contains('BEGIN PUBLIC KEY'));

      final out = actor.toJson();
      expect(out['id'], actor.id);
      expect(out['type'], 'Person');
      expect((out['publicKey'] as Map)['id'], actor.publicKey.id);
    });
  });

  group('ApActivity.fromJson', () {
    test('parses Follow', () {
      final act = ApActivity.fromJson({
        'id': 'https://a.example/activities/1',
        'type': 'Follow',
        'actor': 'https://a.example/users/bob',
        'object': 'https://b.example/users/alice',
      });
      expect(act, isA<ApFollow>());
      expect(act.actor, 'https://a.example/users/bob');
    });

    test('parses Move', () {
      final act = ApActivity.fromJson({
        'id': 'https://a.example/activities/move1',
        'type': 'Move',
        'actor': 'https://a.example/users/alice',
        'object': 'https://a.example/users/alice',
        'target': 'https://b.example/users/alice',
      });
      expect(act, isA<ApMove>());
      expect((act as ApMove).target, 'https://b.example/users/alice');
    });

    test('throws UnrecognizedActivityTypeException for unknown type', () {
      expect(
        () => ApActivity.fromJson({
          'id': 'x',
          'type': 'Explode',
          'actor': 'y',
        }),
        throwsA(isA<UnrecognizedActivityTypeException>()),
      );
    });

    test('round-trips Create through toJson', () {
      final json = {
        'id': 'https://a.example/activities/2',
        'type': 'Create',
        'actor': 'https://a.example/users/bob',
        'object': {'type': 'Note', 'content': 'hello'},
        'to': ['https://www.w3.org/ns/activitystreams#Public'],
      };
      final act = ApActivity.fromJson(json) as ApCreate;
      final out = act.toJson();
      expect(out['type'], 'Create');
      expect(out['actor'], act.actor);
    });
  });

  group('ApOrderedCollection', () {
    test('round-trips', () {
      final col = ApOrderedCollection(
        id: 'https://a.example/users/alice/outbox',
        totalItems: 42,
        first: 'https://a.example/users/alice/outbox?page=1',
      );
      final json = col.toJson();
      expect(json['type'], 'OrderedCollection');
      expect(json['totalItems'], 42);
    });
  });

  group('ApOrderedCollectionPage', () {
    test('round-trips with next/prev', () {
      final page = ApOrderedCollectionPage(
        id: 'https://a.example/users/alice/outbox?page=2',
        partOf: 'https://a.example/users/alice/outbox',
        orderedItems: ['item1', 'item2'],
        next: 'https://a.example/users/alice/outbox?page=3',
        prev: 'https://a.example/users/alice/outbox?page=1',
      );
      final json = page.toJson();
      expect(json['type'], 'OrderedCollectionPage');
      expect(json['next'], page.next);
    });
  });

  group('WebFingerJrd', () {
    test('extracts selfHref', () {
      final jrd = WebFingerJrd.fromJson({
        'subject': 'acct:alice@example.com',
        'links': [
          {
            'rel': 'self',
            'type': 'application/activity+json',
            'href': 'https://example.com/users/alice',
          },
        ],
      });
      expect(jrd.selfHref, 'https://example.com/users/alice');
    });

    test('returns null selfHref when no self link', () {
      final jrd = WebFingerJrd(subject: 'acct:alice@example.com', links: []);
      expect(jrd.selfHref, isNull);
    });
  });

  group('ApPublicKey', () {
    test('round-trips', () {
      final key = ApPublicKey(
        id: 'https://example.com/users/alice#main-key',
        owner: 'https://example.com/users/alice',
        publicKeyPem: '-----BEGIN PUBLIC KEY-----\nABC\n-----END PUBLIC KEY-----\n',
      );
      final json = key.toJson();
      final key2 = ApPublicKey.fromJson(json);
      expect(key2.id, key.id);
      expect(key2.publicKeyPem, key.publicKeyPem);
    });
  });
}
