import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nightingale/core/crypto/crypto_service.dart';

// Key for the private key seed in the secure enclave.
// Only the 32-byte seed is stored; the key object is reconstructed on demand.
const _kPrivateKeySeedKey = 'nightingale_node_ed25519_seed';
const _kPublicKeyBytesKey = 'nightingale_node_ed25519_pub';

class PlatformCryptoService implements CryptoService {
  final FlutterSecureStorage _storage;
  final Ed25519 _algo = Ed25519();

  PlatformCryptoService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  @override
  Future<bool> hasKeyPair() async {
    final seed = await _storage.read(key: _kPrivateKeySeedKey);
    return seed != null;
  }

  @override
  Future<void> generateKeyPair() async {
    final keyPair = await _algo.newKeyPair();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    await _storage.write(
      key: _kPrivateKeySeedKey,
      value: base64Encode(privateBytes),
    );
    await _storage.write(
      key: _kPublicKeyBytesKey,
      value: base64Encode(publicKey.bytes),
    );
  }

  @override
  Future<List<int>> sign(List<int> message) async {
    final keyPair = await _loadKeyPair();
    final sig = await _algo.sign(message, keyPair: keyPair);
    return sig.bytes;
  }

  @override
  Future<String> getPublicKeyPem() async {
    final pubBytesB64 = await _storage.read(key: _kPublicKeyBytesKey);
    if (pubBytesB64 == null) {
      throw StateError('No key pair generated yet');
    }
    final pubBytes = base64Decode(pubBytesB64);
    return _ed25519PublicKeyToPem(pubBytes);
  }

  Future<SimpleKeyPair> _loadKeyPair() async {
    final seedB64 = await _storage.read(key: _kPrivateKeySeedKey);
    if (seedB64 == null) throw StateError('No key pair generated yet');
    final seed = base64Decode(seedB64);
    return _algo.newKeyPairFromSeed(seed);
  }

  // Encode a raw 32-byte Ed25519 public key as a PEM SubjectPublicKeyInfo.
  // DER prefix: SEQUENCE { SEQUENCE { OID 1.3.101.112 } BIT STRING }
  String _ed25519PublicKeyToPem(List<int> rawBytes) {
    // Ed25519 SubjectPublicKeyInfo DER prefix (12 bytes)
    const prefix = [
      0x30, 0x2a, // SEQUENCE, length 42
      0x30, 0x05, // SEQUENCE, length 5
      0x06, 0x03, 0x2b, 0x65, 0x70, // OID 1.3.101.112 (Ed25519)
      0x03, 0x21, 0x00, // BIT STRING, 33 bytes, 0 unused bits
    ];
    final der = Uint8List(prefix.length + rawBytes.length);
    der.setAll(0, prefix);
    der.setAll(prefix.length, rawBytes);

    final b64 = base64.encode(der);
    final wrapped = b64.replaceAllMapped(
      RegExp('.{1,64}'),
      (m) => '${m.group(0)}\n',
    );
    return '-----BEGIN PUBLIC KEY-----\n${wrapped}-----END PUBLIC KEY-----\n';
  }
}
