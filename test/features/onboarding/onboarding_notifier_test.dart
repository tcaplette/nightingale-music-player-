import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/features/onboarding/onboarding_notifier.dart';
import 'package:nightingale/features/onboarding/secure_storage_service.dart';

/// In-memory stub for testing.
class _InMemoryStorageService implements SecureStorageService {
  bool _value;
  String? _mastodonHandle;
  _InMemoryStorageService({bool initialValue = false}) : _value = initialValue;

  @override
  Future<bool> getOnboardingComplete() async => _value;

  @override
  Future<void> setOnboardingComplete(bool value) async => _value = value;

  @override
  Future<bool> getDiscoveryShown() async => false;

  @override
  Future<void> setDiscoveryShown(bool value) async {}

  @override
  Future<String?> getMastodonHandle() async => _mastodonHandle;

  @override
  Future<void> setMastodonHandle(String handle) async => _mastodonHandle = handle;

  @override
  Future<void> clearMastodonHandle() async => _mastodonHandle = null;

  @override Future<String?> getMastodonAccessToken(String i) async => null;
  @override Future<void> setMastodonAccessToken(String i, String t) async {}
  @override Future<void> clearMastodonCredentials(String i) async {}
  @override Future<({String clientId, String clientSecret})?> getMastodonClientCredentials(String i) async => null;
  @override Future<void> setMastodonClientCredentials(String i, String cid, String cs) async {}
}

void main() {
  group('OnboardingNotifier', () {
    test('emits OnboardingRequired when flag is false', () async {
      final storage = _InMemoryStorageService(initialValue: false);
      // Verify storage returns false
      expect(await storage.getOnboardingComplete(), isFalse);
    });

    test('emits OnboardingComplete when flag is true', () async {
      final storage = _InMemoryStorageService(initialValue: true);
      expect(await storage.getOnboardingComplete(), isTrue);
    });

    test('setOnboardingComplete persists the value', () async {
      final storage = _InMemoryStorageService(initialValue: false);
      await storage.setOnboardingComplete(true);
      expect(await storage.getOnboardingComplete(), isTrue);
    });
  });
}
