import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nightingale/features/federation/discovery/mastodon_bridge_service.dart';
import 'package:nightingale/features/onboarding/screens/onboarding_shell.dart';
import 'package:nightingale/features/onboarding/secure_storage_service.dart';
import 'package:nightingale/features/social/providers/social_graph_notifier.dart';
import 'package:nightingale/shared/theme/app_theme.dart';

class _StubSocialGraphNotifier extends StateNotifier<SocialGraphState>
    implements SocialGraphNotifier {
  _StubSocialGraphNotifier() : super(const SocialGraphState());
  @override Future<void> followActor(String a) async {}
  @override Future<void> unfollowActor(String a) async {}
  @override Future<String?> getFollowState(String a) async => null;
  @override Future<void> load() async {}
  @override Future<void> acceptFollowRequest(int r) async {}
  @override Future<void> rejectFollowRequest(int r) async {}
  @override Future<void> blockActor(String a) async {}
  @override Future<void> unblockActor(String a) async {}
  @override Future<void> muteActor(String a) async {}
  @override Future<void> unmuteActor(String a) async {}
  @override Future<bool> isBlocked(String a) async => false;
  @override Future<bool> isMuted(String a) async => false;
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _StubMastodonBridgeService implements MastodonBridgeService {
  @override
  Future<List<MastodonMatch>> importSocialGraph(String handle) async => [];
  @override
  bool isRateLimited(String instance) => false;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// Stub storage that tracks setDiscoveryShown calls.
class _SpyStorage implements SecureStorageService {
  bool discoveryShown = false;
  @override Future<bool> getOnboardingComplete() async => false;
  @override Future<void> setOnboardingComplete(bool v) async {}
  @override Future<bool> getDiscoveryShown() async => discoveryShown;
  @override Future<void> setDiscoveryShown(bool v) async {
    discoveryShown = v;
  }
  @override Future<String?> getMastodonHandle() async => null;
  @override Future<void> setMastodonHandle(String handle) async {}
  @override Future<void> clearMastodonHandle() async {}
  @override Future<String?> getMastodonAccessToken(String i) async => null;
  @override Future<void> setMastodonAccessToken(String i, String t) async {}
  @override Future<void> clearMastodonCredentials(String i) async {}
  @override Future<({String clientId, String clientSecret})?> getMastodonClientCredentials(String i) async => null;
  @override Future<void> setMastodonClientCredentials(String i, String cid, String cs) async {}
}

Widget _wrap(Widget child) => ProviderScope(
      overrides: [
        socialGraphProvider.overrideWith((_) => _StubSocialGraphNotifier()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: child,
      ),
    );

void _registerBridge() {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<MastodonBridgeService>()) {
    getIt.unregister<MastodonBridgeService>();
  }
  getIt.registerSingleton<MastodonBridgeService>(_StubMastodonBridgeService());
}

void _registerStorage(_SpyStorage storage) {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<SecureStorageService>()) {
    getIt.unregister<SecureStorageService>();
  }
  getIt.registerSingleton<SecureStorageService>(storage);
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    _registerBridge();
  });

  tearDown(() async {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<MastodonBridgeService>()) {
      getIt.unregister<MastodonBridgeService>();
    }
    if (getIt.isRegistered<SecureStorageService>()) {
      getIt.unregister<SecureStorageService>();
    }
  });

  testWidgets('shows Find your people headline', (tester) async {
    bool advanced = false;
    await tester.pumpWidget(_wrap(
      DiscoveryOnboardingStep(onNext: () => advanced = true),
    ));
    expect(find.text('Find your people'), findsOneWidget);
    expect(find.text('Connect Mastodon'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
  });

  testWidgets('tapping Connect Mastodon shows the import screen', (tester) async {
    await tester.pumpWidget(_wrap(
      DiscoveryOnboardingStep(onNext: () {}),
    ));
    await tester.tap(find.text('Connect Mastodon'));
    await tester.pumpAndSettle();
    // MastodonImportScreen title and handle input should now be visible
    expect(find.text('Connect Mastodon'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('skip marks discoveryShown and calls onNext', (tester) async {
    final storage = _SpyStorage();
    _registerStorage(storage);

    bool nextCalled = false;
    await tester.pumpWidget(_wrap(
      DiscoveryOnboardingStep(onNext: () => nextCalled = true),
    ));
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(nextCalled, isTrue);
    expect(storage.discoveryShown, isTrue);
  });
}
