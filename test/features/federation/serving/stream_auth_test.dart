import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/core/crypto/crypto_service.dart';
import 'package:shelf/shelf.dart' as shelf;

class _FakeCrypto implements CryptoService {
  @override
  Future<List<int>> sign(List<int> data) async => [1, 2, 3];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Stream Authentication', () {
    late HttpSignatureService sigService;

    setUp(() {
      sigService = HttpSignatureService(
        crypto: _FakeCrypto(),
        keyId: 'http://localhost/users/node#main-key',
        timeWindowSeconds: 300, // generous window for tests
      );
    });

    test('accepts requests without signature for public streams', () async {
      final request = shelf.Request(
        'GET',
        Uri.parse('http://localhost/stream/1'),
      );

      final result = await sigService.verifyRequest(request);
      expect(result, isA<SignatureMissing>());
    });

    test('rejects requests with invalid signature', () async {
      final request = shelf.Request(
        'GET',
        Uri.parse('http://localhost/stream/1'),
        headers: {
          'signature': 'keyId="test",algorithm="ed25519",signature="bad"',
          'date': HttpDate.format(DateTime.now().toUtc()),
        },
      );

      final result = await sigService.verifyRequest(request);
      expect(result, isA<SignatureFailed>());
    });

    test('rejects requests with date outside window', () async {
      final request = shelf.Request(
        'GET',
        Uri.parse('http://localhost/stream/1'),
        headers: {
          'signature': 'keyId="test",algorithm="ed25519",signature="dGVzdA=="',
          'date': HttpDate.format(
            DateTime.now().toUtc().subtract(const Duration(hours: 1)),
          ),
        },
      );

      final result = await sigService.verifyRequest(request);
      expect(result, isA<SignatureFailed>());
    });
  });
}
