import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/crypto/platform_crypto_service.dart';

void main() {
  group('PlatformCryptoService', () {
    late PlatformCryptoService svc;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      svc = PlatformCryptoService();
    });

    test('hasKeyPair returns false before generation', () async {
      expect(await svc.hasKeyPair(), isFalse);
    });

    test('hasKeyPair returns true after generation', () async {
      await svc.generateKeyPair();
      expect(await svc.hasKeyPair(), isTrue);
    });

    test('sign produces a signature verifiable with the public key', () async {
      await svc.generateKeyPair();
      const message = [1, 2, 3, 4, 5];
      final signature = await svc.sign(message);
      expect(signature, hasLength(64));

      final pem = await svc.getPublicKeyPem();
      final pubBytes = _parsePemPublicKeyBytes(pem);
      final pubKey = SimplePublicKey(pubBytes, type: KeyPairType.ed25519);
      final sig = Signature(signature, publicKey: pubKey);
      final valid = await Ed25519().verify(message, signature: sig);
      expect(valid, isTrue);
    });

    test('getPublicKeyPem returns PEM-wrapped key', () async {
      await svc.generateKeyPair();
      final pem = await svc.getPublicKeyPem();
      expect(pem, startsWith('-----BEGIN PUBLIC KEY-----'));
      expect(pem, contains('-----END PUBLIC KEY-----'));
    });

    test('sign returns exactly 64 bytes', () async {
      await svc.generateKeyPair();
      final signature = await svc.sign([0]);
      expect(signature, hasLength(64));
    });
  });
}

// Strip PEM headers and decode SPKI DER, returning the 32-byte raw Ed25519 key.
List<int> _parsePemPublicKeyBytes(String pem) {
  final lines = pem.split('\n').where((l) => !l.startsWith('-----')).join();
  final der = base64.decode(lines);
  return der.sublist(12); // 12-byte SPKI prefix; raw key follows
}
