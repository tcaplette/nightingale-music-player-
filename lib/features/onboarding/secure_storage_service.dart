import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kOnboardingCompleteKey = 'nightingale_onboarding_complete';
const _kDiscoveryShownKey = 'nightingale_onboarding_discovery_shown';
const _kMastodonHandleKey = 'nightingale_mastodon_handle';

abstract interface class SecureStorageService {
  Future<bool> getOnboardingComplete();
  Future<void> setOnboardingComplete(bool value);
  Future<bool> getDiscoveryShown();
  Future<void> setDiscoveryShown(bool value);
  Future<String?> getMastodonHandle();
  Future<void> setMastodonHandle(String handle);
  Future<void> clearMastodonHandle();
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

  @override
  Future<bool> getDiscoveryShown() async {
    final value = await _storage.read(key: _kDiscoveryShownKey);
    return value == 'true';
  }

  @override
  Future<void> setDiscoveryShown(bool value) =>
      _storage.write(key: _kDiscoveryShownKey, value: value.toString());

  @override
  Future<String?> getMastodonHandle() =>
      _storage.read(key: _kMastodonHandleKey);

  @override
  Future<void> setMastodonHandle(String handle) =>
      _storage.write(key: _kMastodonHandleKey, value: handle);

  @override
  Future<void> clearMastodonHandle() =>
      _storage.delete(key: _kMastodonHandleKey);
}
