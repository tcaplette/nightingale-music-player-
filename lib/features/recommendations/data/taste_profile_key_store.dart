import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kTasteProfileKeyStorageKey = 'nightingale_taste_profile_aes256_key';

class TasteProfileKeyStore {
  TasteProfileKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  final FlutterSecureStorage _storage;
  final AesGcm _algo = AesGcm.with256bits();

  SecretKey? _cachedKey;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Returns the AES-256 key for encrypting/decrypting the taste profile.
  /// Throws [StateError] if [loadOrCreate] has not been called yet.
  Future<SecretKey> getKey() async {
    if (!_loaded || _cachedKey == null) {
      throw StateError(
        'Taste profile key not loaded. Call loadOrCreate() before reading signal data.',
      );
    }
    return _cachedKey!;
  }

  /// Loads the key from secure storage, or generates a new one on first launch.
  Future<void> loadOrCreate() async {
    final encoded = await _storage.read(key: _kTasteProfileKeyStorageKey);
    if (encoded == null) {
      final key = await _algo.newSecretKey();
      final bytes = await key.extractBytes();
      await _storage.write(
        key: _kTasteProfileKeyStorageKey,
        value: base64Encode(bytes),
      );
      _cachedKey = key;
    } else {
      final bytes = base64Decode(encoded);
      _cachedKey = SecretKey(Uint8List.fromList(bytes));
    }
    _loaded = true;
  }

  /// Encrypt [plaintext] using the loaded key.
  /// Returns a base64-encoded string of nonce + ciphertext + MAC.
  Future<String> encrypt(String plaintext) async {
    final key = await getKey();
    final nonce = _algo.newNonce();
    final secretBox = await _algo.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );
    final combined = [
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];
    return base64Encode(combined);
  }

  /// Decrypt a value previously encrypted with [encrypt].
  Future<String> decrypt(String encoded) async {
    final key = await getKey();
    final combined = base64Decode(encoded);
    // AES-GCM nonce is 12 bytes, MAC is 16 bytes
    const nonceLength = 12;
    const macLength = 16;
    final nonce = combined.sublist(0, nonceLength);
    final mac = combined.sublist(combined.length - macLength);
    final cipherText = combined.sublist(nonceLength, combined.length - macLength);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
    final plain = await _algo.decrypt(secretBox, secretKey: key);
    return utf8.decode(plain);
  }
}
