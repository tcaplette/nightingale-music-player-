import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/activitypub/models/ap_activity.dart';

void main() {
  group('ApListen', () {
    test('can be created and serialized', () {
      final activity = ApListen(
        id: 'http://localhost/users/node/listen/123',
        actor: 'http://localhost/users/node',
        object: {
          'type': 'Audio',
          'id': 'http://localhost/users/node/tracks/1',
          'name': 'Test Song',
          'artist': 'Test Artist',
        },
        published: DateTime.utc(2024, 1, 1),
      );

      final json = activity.toJson();
      expect(json['type'], 'Listen');
      expect(json['actor'], 'http://localhost/users/node');
      expect(json['object']['name'], 'Test Song');
    });

    test('can be deserialized from JSON', () {
      final json = {
        '@context': 'https://www.w3.org/ns/activitystreams',
        'id': 'http://localhost/users/node/listen/123',
        'type': 'Listen',
        'actor': 'http://localhost/users/node',
        'object': {
          'type': 'Audio',
          'id': 'http://localhost/users/node/tracks/1',
          'name': 'Test Song',
          'artist': 'Test Artist',
        },
        'published': '2024-01-01T00:00:00.000Z',
      };

      final activity = ApActivity.fromJson(json);
      expect(activity, isA<ApListen>());
      expect(activity.id, 'http://localhost/users/node/listen/123');
    });
  });
}
