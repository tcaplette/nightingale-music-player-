import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/activitypub/activity_sanitizer.dart';
import 'package:nightingale/core/activitypub/activity_validator.dart';

void main() {
  const sanitizer = ActivitySanitizer();
  const validator = ActivityValidator();

  group('ActivitySanitizer', () {
    test('strips HTML from name field', () {
      final result = sanitizer.sanitize(
        '{"type":"Follow","id":"https://a.example/1","actor":"https://a.example/users/bob","name":"<b>Evil</b> Name"}',
      );
      expect(result, isA<SanitizerOk>());
      final json = (result as SanitizerOk).json;
      expect(json['name'], 'Evil Name');
    });

    test('nulls out non-HTTPS url field', () {
      final result = sanitizer.sanitize(
        '{"type":"Follow","id":"https://a.example/1","actor":"https://a.example/users/bob","url":"http://evil.example/img.png"}',
      );
      expect(result, isA<SanitizerOk>());
      final json = (result as SanitizerOk).json;
      expect(json['url'], isNull);
    });

    test('accepts HTTPS url field', () {
      final result = sanitizer.sanitize(
        '{"type":"Follow","id":"https://a.example/1","actor":"https://a.example/users/bob","url":"https://safe.example/img.png"}',
      );
      final json = (result as SanitizerOk).json;
      expect(json['url'], 'https://safe.example/img.png');
    });

    test('rejects invalid JSON', () {
      final result = sanitizer.sanitize('{not json}');
      expect(result, isA<SanitizerRejected>());
    });

    test('rejects oversized payload', () {
      final big = '{"a":"${'x' * (64 * 1024 + 1)}"}';
      final result = sanitizer.sanitize(big);
      expect(result, isA<SanitizerRejected>());
    });
  });

  group('ActivityValidator', () {
    test('validates known type', () {
      final result = validator.validate({
        'id': 'https://a.example/1',
        'type': 'Follow',
        'actor': 'https://a.example/users/bob',
        'object': 'https://b.example/users/alice',
      });
      expect(result, isA<ValidationOk>());
    });

    test('drops unknown type', () {
      final result = validator.validate({
        'id': 'https://a.example/1',
        'type': 'Explode',
        'actor': 'https://a.example/users/bob',
      });
      expect(result, isA<ValidationDropped>());
    });
  });
}
