import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart' as shelf;
import 'package:nightingale/core/crypto/platform_crypto_service.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';

void main() {
  group('HttpSignatureService', () {
    late PlatformCryptoService crypto;
    late HttpSignatureService svc;
    const actorUrl = 'https://example.com/users/alice';
    const keyId = '$actorUrl#main-key';

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      crypto = PlatformCryptoService();
      await crypto.generateKeyPair();
      svc = HttpSignatureService(crypto: crypto, keyId: keyId);
    });

    test('signRequest adds Date, digest, and Signature headers', () async {
      final req = http.Request(
        'POST',
        Uri.parse('https://b.example/users/bob/inbox'),
      )..body = '{"type":"Follow"}';

      final signed = await svc.signRequest(req);
      expect(signed.headers.containsKey('date'), isTrue);
      expect(signed.headers.containsKey('digest'), isTrue);
      expect(signed.headers.containsKey('signature'), isTrue);
      expect(signed.headers['signature'], contains('keyId="$keyId"'));
    });

    test('verifyRequest rejects missing signature', () async {
      final req = _makeShelfRequest('POST', {});
      final result = await svc.verifyRequest(req);
      expect(result, isA<SignatureMissing>());
    });

    test('verifyRequest rejects expired Date', () async {
      final staleDate = HttpDate.format(
        DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      );
      final req = _makeShelfRequest('POST', {
        'signature':
            'keyId="$keyId",algorithm="ed25519",headers="date",signature="AAAA"',
        'date': staleDate,
      });
      final result = await svc.verifyRequest(req);
      expect(result, isA<SignatureFailed>());
    });

    test('verifyRequest rejects replayed nonce', () async {
      final now = HttpDate.format(DateTime.now().toUtc());
      final headers = {
        'signature':
            'keyId="$keyId",algorithm="ed25519",nonce="abc123",'
            'headers="date",signature="AAAA"',
        'date': now,
      };
      // First request records the nonce — will fail sig verification but nonce is stored
      await svc.verifyRequest(_makeShelfRequest('POST', headers));
      // Second request with the same nonce must be rejected before sig check
      final result = await svc.verifyRequest(_makeShelfRequest('POST', headers));
      expect(result, isA<SignatureReplayed>());
    });
  });
}

shelf.Request _makeShelfRequest(
  String method,
  Map<String, String> extraHeaders,
) =>
    shelf.Request(
      method,
      Uri.parse('https://example.com/users/alice/inbox'),
      headers: extraHeaders,
    );
