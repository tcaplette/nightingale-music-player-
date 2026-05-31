import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/features/recommendations/data/cold_start_settings_repository.dart';
import 'package:nightingale/features/recommendations/data/global_trending_relay_service.dart';

void main() {
  group('ColdStartSettingsRepository', () {
    late ColdStartSettingsRepository repo;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      repo = ColdStartSettingsRepository();
    });

    test('global trending is disabled by default', () async {
      expect(await repo.isGlobalTrendingEnabled(), isFalse);
    });

    test('discovery is enabled by default (opt-out)', () async {
      expect(await repo.isDiscoveryEnabled(), isTrue);
    });

    test('can enable and disable global trending', () async {
      await repo.setGlobalTrendingEnabled(true);
      expect(await repo.isGlobalTrendingEnabled(), isTrue);

      await repo.setGlobalTrendingEnabled(false);
      expect(await repo.isGlobalTrendingEnabled(), isFalse);
    });
  });

  group('GlobalTrendingRelayService', () {
    test('returns empty list when opt-in is false', () async {
      final service = GlobalTrendingRelayService(relayEndpoint: 'http://example.com/trending');
      final results = await service.fetchTrending(optedIn: false);
      expect(results, isEmpty);
    });

    test('returns empty list when endpoint is null', () async {
      final service = GlobalTrendingRelayService(relayEndpoint: null);
      final results = await service.fetchTrending(optedIn: true);
      expect(results, isEmpty);
    });

    test('returns empty list when endpoint is empty string', () async {
      final service = GlobalTrendingRelayService(relayEndpoint: '');
      final results = await service.fetchTrending(optedIn: true);
      expect(results, isEmpty);
    });
  });
}
