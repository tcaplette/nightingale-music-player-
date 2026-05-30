import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kDiscoveryOptInKey = 'nightingale_cold_start_discovery_enabled';
const _kGlobalTrendingOptInKey = 'nightingale_cold_start_trending_enabled';

class ColdStartSettingsRepository {
  ColdStartSettingsRepository({FlutterSecureStorage? storage})
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

  Future<bool> isDiscoveryEnabled() async {
    final v = await _storage.read(key: _kDiscoveryOptInKey);
    return v == 'true';
  }

  Future<void> setDiscoveryEnabled(bool enabled) =>
      _storage.write(key: _kDiscoveryOptInKey, value: enabled.toString());

  // Global trending is disabled by default per spec.
  Future<bool> isGlobalTrendingEnabled() async {
    final v = await _storage.read(key: _kGlobalTrendingOptInKey);
    return v == 'true';
  }

  Future<void> setGlobalTrendingEnabled(bool enabled) async {
    await _storage.write(
        key: _kGlobalTrendingOptInKey, value: enabled.toString());
    if (!enabled) await _clearRelayCache();
  }

  Future<void> _clearRelayCache() async {
    // Relay data is in-memory only (GlobalTrendingRelayService caches per session).
    // No persistent relay data to purge.
  }
}
