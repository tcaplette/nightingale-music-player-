import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/activitypub/models/ap_public_key.dart';
import 'package:nightingale/core/di/service_locator.dart' show sl;
import 'package:nightingale/features/federation/discovery/mastodon_bridge_service.dart';
import 'package:nightingale/features/federation/screens/mastodon_import_screen.dart';
import 'package:nightingale/features/social/providers/social_graph_notifier.dart';
import 'package:nightingale/shared/theme/app_theme.dart';

// Stub SocialRepository for provider overrides.
class _StubSocialGraphNotifier extends StateNotifier<SocialGraphState>
    implements SocialGraphNotifier {
  _StubSocialGraphNotifier() : super(const SocialGraphState());

  @override
  Future<void> followActor(String actorUrl) async {
    state = SocialGraphState(
      following: [
        ...state.following,
      ],
    );
  }

  @override
  Future<void> unfollowActor(String actorUrl) async {}
  @override
  Future<String?> getFollowState(String actorUrl) async => null;
  @override
  Future<void> load() async {}
  @override
  Future<void> acceptFollowRequest(int requestRowId) async {}
  @override
  Future<void> rejectFollowRequest(int requestRowId) async {}
  @override
  Future<void> blockActor(String actorUrl) async {}
  @override
  Future<void> unblockActor(String actorUrl) async {}
  @override
  Future<void> muteActor(String actorUrl) async {}
  @override
  Future<void> unmuteActor(String actorUrl) async {}
  @override
  Future<bool> isBlocked(String actorUrl) async => false;
  @override
  Future<bool> isMuted(String actorUrl) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubMastodonBridgeService implements MastodonBridgeService {
  final List<MastodonMatch> stubMatches;
  _StubMastodonBridgeService({this.stubMatches = const []});

  @override
  Future<List<MastodonMatch>> importSocialGraph(String handle) async =>
      stubMatches;

  @override
  bool isRateLimited(String instance) => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(Widget child, {_StubMastodonBridgeService? bridge}) {
  return ProviderScope(
    overrides: [
      socialGraphProvider.overrideWith(
        (ref) => _StubSocialGraphNotifier(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: child,
    ),
  );
}

void _registerBridge(_StubMastodonBridgeService bridge) {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<MastodonBridgeService>()) {
    getIt.unregister<MastodonBridgeService>();
  }
  getIt.registerSingleton<MastodonBridgeService>(bridge);
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<MastodonBridgeService>()) {
      getIt.unregister<MastodonBridgeService>();
    }
  });

  testWidgets('MastodonImportScreen shows handle input and skip button',
      (tester) async {
    _registerBridge(_StubMastodonBridgeService());
    await tester.pumpWidget(_wrap(const MastodonImportScreen()));
    expect(find.text('Connect Mastodon'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Skip calls onDone callback', (tester) async {
    _registerBridge(_StubMastodonBridgeService());
    bool doneCalled = false;
    await tester.pumpWidget(
      _wrap(MastodonImportScreen(onDone: () => doneCalled = true)),
    );
    await tester.tap(find.text('Skip'));
    expect(doneCalled, isTrue);
  });

  testWidgets('Shows validation error for malformed handle', (tester) async {
    _registerBridge(_StubMastodonBridgeService());
    await tester.pumpWidget(_wrap(const MastodonImportScreen()));
    await tester.enterText(find.byType(TextField), 'notahandle');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    expect(
      find.text('Enter a handle like @you@mastodon.social'),
      findsOneWidget,
    );
  });

  testWidgets('Shows empty state when no matches found', (tester) async {
    _registerBridge(_StubMastodonBridgeService(stubMatches: []));
    await tester.pumpWidget(_wrap(const MastodonImportScreen()));
    await tester.enterText(
        find.byType(TextField), '@howard@mastodon.social');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('None of your Mastodon connections'),
      findsOneWidget,
    );
  });

  testWidgets('Shows match cards when matches are found', (tester) async {
    _registerBridge(_StubMastodonBridgeService(
      stubMatches: [
        const MastodonMatch(
          actorUrl: 'https://example.com/users/alice',
          displayName: 'Alice',
        ),
      ],
    ));
    await tester.pumpWidget(_wrap(const MastodonImportScreen()));
    await tester.enterText(
        find.byType(TextField), '@howard@mastodon.social');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Follow all'), findsOneWidget);
  });
}
