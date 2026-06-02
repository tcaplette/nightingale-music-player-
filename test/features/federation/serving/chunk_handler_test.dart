import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/core/crypto/crypto_service.dart';
import 'package:shelf/shelf.dart' as shelf;

// Mirrors stream_auth_test.dart pattern: tests the authentication/signature
// logic used by the chunk endpoint in isolation. Full handler responses
// (404/503/200) are verified via the integration harness.

class _FakeCrypto implements CryptoService {
  @override
  Future<List<int>> sign(List<int> data) async => List.filled(64, 1);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Chunk handler — HTTP Signature verification', () {
    late HttpSignatureService sigService;

    setUp(() {
      sigService = HttpSignatureService(
        crypto: _FakeCrypto(),
        keyId: 'http://localhost/users/node#main-key',
        timeWindowSeconds: 300,
      );
    });

    test('anonymous request produces SignatureMissing', () async {
      final request = shelf.Request(
        'GET',
        Uri.parse(
            'http://localhost/chunks/aabbccddeeff00112233445566778899'
            'aabbccddeeff00112233445566778899'),
      );
      final result = await sigService.verifyRequest(request);
      expect(result, isA<SignatureMissing>());
    });

    test('malformed signature header produces SignatureFailed', () async {
      final request = shelf.Request(
        'GET',
        Uri.parse(
            'http://localhost/chunks/aabbccddeeff00112233445566778899'
            'aabbccddeeff00112233445566778899'),
        headers: {
          'signature': 'keyId="http://peer/users/bob#main-key",'
              'algorithm="ed25519",signature="notvalidbase64=="',
          'date': DateTime.now().toUtc().toIso8601String(),
        },
      );
      final result = await sigService.verifyRequest(request);
      expect(result, isA<SignatureFailed>());
    });
  });

  group('Chunk handler — hash format validation', () {
    Uint8List? _parseHex(String hex) {
      if (hex.length != 64 || !RegExp(r'^[0-9a-f]+$').hasMatch(hex)) {
        return null;
      }
      final result = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
      }
      return result;
    }

    test('valid 64-char hex is parsed correctly', () {
      const hash =
          'aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899';
      final bytes = _parseHex(hash);
      expect(bytes, isNotNull);
      expect(bytes!.length, 32);
    });

    test('too-short hash returns null', () {
      expect(_parseHex('aabb'), isNull);
    });

    test('non-hex characters return null', () {
      const bad =
          'GGBBCCDDEEFF00112233445566778899aabbccddeeff00112233445566778899';
      expect(_parseHex(bad.toLowerCase().replaceFirst('gg', 'zz')), isNull);
    });
  });
}
