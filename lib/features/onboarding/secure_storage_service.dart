import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kOnboardingCompleteKey = 'nightingale_onboarding_complete';

abstract interface class SecureStorageService {
  Future<bool> getOnboardingComplete();
  Future<void> setOnboardingComplete(bool value);
}

class FlutterSecureStorageService implements SecureStorageService {
  FlutterSecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<bool> getOnboardingComplete() async {
    final value = await _storage.read(key: _kOnboardingCompleteKey);
    return value == 'true';
  }

  @override
  Future<void> setOnboardingComplete(bool value) =>
      _storage.write(key: _kOnboardingCompleteKey, value: value.toString());
}
