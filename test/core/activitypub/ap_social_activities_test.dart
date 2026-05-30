import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/activitypub/models/ap_activity.dart';

void main() {
  group('ApBlock', () {
    test('round-trips through fromJson/toJson', () {
      final json = {
        '@context': 'https://www.w3.org/ns/activitystreams',
        'id': 'https://node.example/block/1',
        'type': 'Block',
        'actor': 'https://node.example/users/alice',
        'object': 'https://other.example/users/bob',
        'published': '2025-01-01T00:00:00.000Z',
      };
      final activity = ApActivity.fromJson(json);
      expect(activity, isA<ApBlock>());
      final back = activity.toJson();
      expect(back['type'], 'Block');
      expect(back['actor'], 'https://node.example/users/alice');
      expect(back['object'], 'https://other.example/users/bob');
    });
  });

  group('ApFollow', () {
    test('round-trips through fromJson/toJson', () {
      final json = {
        '@context': 'https://www.w3.org/ns/activitystreams',
        'id': 'https://node.example/follow/1',
        'type': 'Follow',
        'actor': 'https://node.example/users/alice',
        'object': 'https://other.example/users/bob',
      };
      final activity = ApActivity.fromJson(json);
      expect(activity, isA<ApFollow>());
      final back = activity.toJson();
      expect(back['type'], 'Follow');
    });
  });

  group('ApUndo wrapping Follow', () {
    test('round-trips and type is Undo', () {
      final json = {
        '@context': 'https://www.w3.org/ns/activitystreams',
        'id': 'https://node.example/undo/1',
        'type': 'Undo',
        'actor': 'https://node.example/users/alice',
        'object': {
          'type': 'Follow',
          'actor': 'https://node.example/users/alice',
          'object': 'https://other.example/users/bob',
        },
      };
      final activity = ApActivity.fromJson(json);
      expect(activity, isA<ApUndo>());
      final back = activity.toJson();
      expect(back['type'], 'Undo');
      expect((back['object'] as Map)['type'], 'Follow');
    });
  });

  group('ApLike', () {
    test('round-trips through fromJson/toJson', () {
      final json = {
        '@context': 'https://www.w3.org/ns/activitystreams',
        'id': 'https://node.example/like/1',
        'type': 'Like',
        'actor': 'https://node.example/users/alice',
        'object': 'https://other.example/tracks/42',
      };
      final activity = ApActivity.fromJson(json);
      expect(activity, isA<ApLike>());
      expect(activity.toJson()['type'], 'Like');
    });
  });

  group('ApAnnounce', () {
    test('round-trips through fromJson/toJson', () {
      final json = {
        '@context': 'https://www.w3.org/ns/activitystreams',
        'id': 'https://node.example/announce/1',
        'type': 'Announce',
        'actor': 'https://node.example/users/alice',
        'object': 'https://other.example/tracks/42',
      };
      final activity = ApActivity.fromJson(json);
      expect(activity, isA<ApAnnounce>());
      expect(activity.toJson()['type'], 'Announce');
    });
  });

  group('ApAccept / ApReject wrapping Follow', () {
    test('Accept round-trips', () {
      final json = {
        'id': 'https://node.example/accept/1',
        'type': 'Accept',
        'actor': 'https://other.example/users/bob',
        'object': {
          'type': 'Follow',
          'id': 'https://node.example/follow/1',
          'actor': 'https://node.example/users/alice',
          'object': 'https://other.example/users/bob',
        },
      };
      final activity = ApActivity.fromJson(json);
      expect(activity, isA<ApAccept>());
    });

    test('Reject round-trips', () {
      final json = {
        'id': 'https://node.example/reject/1',
        'type': 'Reject',
        'actor': 'https://other.example/users/bob',
        'object': {
          'type': 'Follow',
          'id': 'https://node.example/follow/1',
        },
      };
      final activity = ApActivity.fromJson(json);
      expect(activity, isA<ApReject>());
    });
  });

  group('ApCreate wrapping OrderedCollection (playlist)', () {
    test('round-trips', () {
      final json = {
        'id': 'https://node.example/create/1',
        'type': 'Create',
        'actor': 'https://node.example/users/alice',
        'object': {
          'type': 'OrderedCollection',
          'id': 'https://node.example/users/alice/playlists/1',
          'totalItems': 3,
          'orderedItems': [],
        },
      };
      final activity = ApActivity.fromJson(json);
      expect(activity, isA<ApCreate>());
      expect((activity.object as Map)['type'], 'OrderedCollection');
    });
  });

  group('Unknown activity type throws', () {
    test('throws UnrecognizedActivityTypeException', () {
      final json = {
        'id': 'https://node.example/x/1',
        'type': 'UnknownType',
        'actor': 'https://node.example/users/alice',
      };
      expect(
        () => ApActivity.fromJson(json),
        throwsA(isA<UnrecognizedActivityTypeException>()),
      );
    });
  });
}
