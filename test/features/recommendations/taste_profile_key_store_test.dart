import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/features/recommendations/data/taste_profile_key_store.dart';

void main() {
  group('TasteProfileKeyStore', () {
    late TasteProfileKeyStore store;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      store = TasteProfileKeyStore();
    });

    test('getKey throws StateError before loadOrCreate is called', () async {
      expect(() => store.getKey(), throwsStateError);
    });

    test('isLoaded is false before loadOrCreate', () {
      expect(store.isLoaded, isFalse);
    });

    test('first-launch generates a valid AES-256 key and stores it', () async {
      await store.loadOrCreate();
      expect(store.isLoaded, isTrue);
      final key = await store.getKey();
      final bytes = await key.extractBytes();
      expect(bytes.length, equals(32)); // 256 bits
    });

    test('subsequent loadOrCreate returns the same key bytes', () async {
      await store.loadOrCreate();
      final firstKey = await (await store.getKey()).extractBytes();

      // Create a second instance backed by the same mock storage
      final store2 = TasteProfileKeyStore();
      await store2.loadOrCreate();
      final secondKey = await (await store2.getKey()).extractBytes();

      expect(firstKey, equals(secondKey));
    });

    test('encrypt and decrypt round-trip', () async {
      await store.loadOrCreate();
      const plaintext = 'test:fingerprint';
      final encrypted = await store.encrypt(plaintext);
      final decrypted = await store.decrypt(encrypted);
      expect(decrypted, equals(plaintext));
    });

    test('each encryption of the same plaintext produces different ciphertext (nonce randomness)', () async {
      await store.loadOrCreate();
      const plaintext = 'artist:title';
      final a = await store.encrypt(plaintext);
      final b = await store.encrypt(plaintext);
      expect(a, isNot(equals(b)));
    });
  });
}
