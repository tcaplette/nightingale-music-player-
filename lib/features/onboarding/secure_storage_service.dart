import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kOnboardingCompleteKey = 'nightingale_onboarding_complete';
const _kDiscoveryShownKey = 'nightingale_onboarding_discovery_shown';
const _kMastodonHandleKey = 'nightingale_mastodon_handle';

String _oauthTokenKey(String instance) => 'nightingale_oauth_token_$instance';
String _oauthClientIdKey(String instance) => 'nightingale_oauth_client_id_$instance';
String _oauthClientSecretKey(String instance) => 'nightingale_oauth_client_secret_$instance';

abstract interface class SecureStorageService {
  Future<bool> getOnboardingComplete();
  Future<void> setOnboardingComplete(bool value);
  Future<bool> getDiscoveryShown();
  Future<void> setDiscoveryShown(bool value);
  Future<String?> getMastodonHandle();
  Future<void> setMastodonHandle(String handle);
  Future<void> clearMastodonHandle();

  // Mastodon OAuth
  Future<String?> getMastodonAccessToken(String instance);
  Future<void> setMastodonAccessToken(String instance, String token);
  Future<void> clearMastodonCredentials(String instance);
  Future<({String clientId, String clientSecret})?> getMastodonClientCredentials(String instance);
  Future<void> setMastodonClientCredentials(String instance, String clientId, String clientSecret);
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

  @override
  Future<String?> getMastodonAccessToken(String instance) =>
      _storage.read(key: _oauthTokenKey(instance));

  @override
  Future<void> setMastodonAccessToken(String instance, String token) =>
      _storage.write(key: _oauthTokenKey(instance), value: token);

  @override
  Future<void> clearMastodonCredentials(String instance) async {
    await _storage.delete(key: _oauthTokenKey(instance));
    await _storage.delete(key: _oauthClientIdKey(instance));
    await _storage.delete(key: _oauthClientSecretKey(instance));
  }

  @override
  Future<({String clientId, String clientSecret})?> getMastodonClientCredentials(
    String instance,
  ) async {
    final clientId = await _storage.read(key: _oauthClientIdKey(instance));
    final clientSecret = await _storage.read(key: _oauthClientSecretKey(instance));
    if (clientId == null || clientSecret == null) return null;
    return (clientId: clientId, clientSecret: clientSecret);
  }

  @override
  Future<void> setMastodonClientCredentials(
    String instance,
    String clientId,
    String clientSecret,
  ) async {
    await _storage.write(key: _oauthClientIdKey(instance), value: clientId);
    await _storage.write(key: _oauthClientSecretKey(instance), value: clientSecret);
  }
}
