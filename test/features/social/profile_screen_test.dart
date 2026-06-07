import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/activitypub/models/ap_public_key.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/repositories/activity_repository.dart';
import 'package:nightingale/core/repositories/social_repository.dart';
import 'package:nightingale/features/social/providers/profile_notifier.dart';
import 'package:nightingale/features/social/providers/social_graph_notifier.dart';
import 'package:nightingale/features/social/screens/profile_screen.dart';
import 'package:nightingale/shared/theme/app_theme.dart';

AppDatabase _testDb() => AppDatabase(NativeDatabase.memory());

// ── Minimal stub repos ────────────────────────────────────────────────────────

class _StubActivityRepo implements ActivityRepository {
  @override Future<void> emitNowPlaying({required String trackId, required String trackTitle, required String trackArtist, required String hostingNodeUrl}) async {}
  @override Future<void> likeTrack({required String trackId, required String hostingNodeInbox}) async {}
  @override Future<void> unlikeTrack({required String trackId, required String hostingNodeInbox}) async {}
  @override Future<bool> isLiked(String trackId) async => false;
  @override Future<void> shareTrack({required String trackObjectUrl, required String trackTitle, required String trackArtist}) async {}
  @override Future<void> sharePlaylist(String url) async {}
  @override Future<void> saveTrack({required String trackId, required String trackTitle, required String trackArtist, required String hostingNodeUrl}) async {}
  @override Future<int> publishPlaylist({required String title, required List<String> trackIds, required String visibility}) async => 0;
  @override Future<void> unpublishPlaylist(int id) async {}
  @override Future<List<PlaylistsTableData>> getLocalPlaylists() async => [];
  @override Future<List<SocialActivitiesTableData>> getFeedPage({required int limit, required int offset, required List<String> excludeActorUrls}) async => [];
  @override Future<void> processIncomingActivity({required String activityId, required String type, required String actorUrl, required dynamic objectData, required String rawJson, required DateTime publishedAt, required bool isFromMuted, required bool isHostedLocally}) async {}
}

class _StubSocialRepo implements SocialRepository {
  @override Future<FollowResult> followActor(String actorUrl, {String? mastodonHandle}) async => FollowSuccess();
  @override Future<void> unfollowActor(String actorUrl) async {}
  @override Future<String?> getFollowState(String actorUrl) async => null;
  @override Future<List<FollowsTableData>> getFollowing() async => [];
  @override Future<List<FollowRequestsTableData>> getOutgoingPendingRequests() async => [];
  @override Future<void> acceptFollowRequest(int requestRowId) async {}
  @override Future<void> rejectFollowRequest(int requestRowId) async {}
  @override Future<List<FollowRequestsTableData>> getIncomingPendingRequests() async => [];
  @override Future<List<FollowersTableData>> getFollowers() async => [];
  @override Future<void> blockActor(String actorUrl) async {}
  @override Future<void> unblockActor(String actorUrl) async {}
  @override Future<bool> isBlocked(String actorUrl) async => false;
  @override Future<List<BlocksTableData>> getBlocks() async => [];
  @override Future<void> muteActor(String actorUrl) async {}
  @override Future<void> unmuteActor(String actorUrl) async {}
  @override Future<bool> isMuted(String actorUrl) async => false;
  @override Future<List<MutesTableData>> getMutes() async => [];
  @override Future<void> handleIncomingFollow({required String actorUrl, required String activityId, required bool manuallyApprovesFollowers}) async {}
  @override Future<void> handleIncomingAccept(String originalActivityId) async {}
  @override Future<void> handleIncomingReject(String originalActivityId) async {}
}

// ── Stub notifiers ────────────────────────────────────────────────────────────

class _StubProfileNotifier extends ProfileNotifier {
  final ProfileState _fixed;

  _StubProfileNotifier(this._fixed)
      : super(
          actorUrl: _actorUrl,
          socialRepo: _StubSocialRepo(),
          activityRepo: _StubActivityRepo(),
          actorResolver: ActorResolver(db: _testDb()),
        );

  @override
  Future<void> load() async => state = _fixed;
}

class _StubSocialGraphNotifier extends SocialGraphNotifier {
  _StubSocialGraphNotifier() : super(_StubSocialRepo());

  @override
  Future<void> load() async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _actorUrl = 'https://other.example/users/maya';

ApActor _fakeActor() => ApActor(
      id: _actorUrl,
      type: 'Person',
      inbox: '$_actorUrl/inbox',
      outbox: '$_actorUrl/outbox',
      followers: '$_actorUrl/followers',
      following: '$_actorUrl/following',
      preferredUsername: 'maya',
      name: 'Maya Patel',
      publicKey: const ApPublicKey(
        id: '$_actorUrl#main-key',
        owner: _actorUrl,
        publicKeyPem:
            '-----BEGIN PUBLIC KEY-----\nABC\n-----END PUBLIC KEY-----',
      ),
    );

Widget _wrap(ProfileState profileState) => ProviderScope(
      overrides: [
        profileProvider(_actorUrl).overrideWith(
          (ref) => _StubProfileNotifier(profileState),
        ),
        socialGraphProvider.overrideWith(
          (ref) => _StubSocialGraphNotifier(),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) =>
                  const ProfileScreen(actorUrl: _actorUrl),
            ),
          ],
        ),
      ),
    );

void main() {
  group('ProfileScreen follow button states', () {
    testWidgets('shows "Follow" when not following', (tester) async {
      await tester.pumpWidget(
        _wrap(ProfileState(
          actor: _fakeActor(),
          followState: null,
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();
      expect(find.text('Follow'), findsOneWidget);
    });

    testWidgets('shows "Following" when accepted', (tester) async {
      await tester.pumpWidget(
        _wrap(ProfileState(
          actor: _fakeActor(),
          followState: 'accepted',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();
      expect(find.text('Following'), findsOneWidget);
    });

    testWidgets('shows "Requested" and "Awaiting approval" when pending',
        (tester) async {
      await tester.pumpWidget(
        _wrap(ProfileState(
          actor: _fakeActor(),
          followState: 'pending',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();
      expect(find.text('Requested'), findsOneWidget);
      expect(find.text('Awaiting approval'), findsOneWidget);
    });

    testWidgets('shows "Unblock" and hides Follow when blocked', (tester) async {
      await tester.pumpWidget(
        _wrap(ProfileState(
          actor: _fakeActor(),
          followState: null,
          isBlocked: true,
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unblock'), findsOneWidget);
      expect(find.text('Follow'), findsNothing);
    });
  });

  group('ProfileScreen – humans not handles', () {
    testWidgets('raw handle NOT visible; "Advanced info" affordance shown',
        (tester) async {
      await tester.pumpWidget(
        _wrap(ProfileState(
          actor: _fakeActor(),
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('@maya@'), findsNothing);
      expect(find.text('Advanced info'), findsOneWidget);
    });
  });
}
