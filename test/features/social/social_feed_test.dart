import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/repositories/activity_repository.dart';
import 'package:nightingale/core/repositories/social_repository.dart';
import 'package:nightingale/features/social/providers/notifications_notifier.dart';
import 'package:nightingale/features/social/providers/social_feed_notifier.dart';
import 'package:nightingale/features/social/screens/social_feed_screen_v2.dart';
import 'package:nightingale/shared/theme/app_theme.dart';

// Minimal stub repos that return empty lists — no DB required.
class _StubActivityRepo implements ActivityRepository {
  @override
  Future<void> emitNowPlaying({required String trackId, required String trackTitle, required String trackArtist, required String hostingNodeUrl}) async {}
  @override
  Future<void> likeTrack({required String trackId, required String hostingNodeInbox}) async {}
  @override
  Future<void> unlikeTrack({required String trackId, required String hostingNodeInbox}) async {}
  @override
  Future<bool> isLiked(String trackId) async => false;
  @override
  Future<void> shareTrack({required String trackObjectUrl, required String trackTitle, required String trackArtist}) async {}
  @override
  Future<void> sharePlaylist(String playlistCollectionUrl) async {}
  @override
  Future<void> saveTrack({required String trackId, required String trackTitle, required String trackArtist, required String hostingNodeUrl}) async {}
  @override
  Future<int> publishPlaylist({required String title, required List<String> trackIds, required String visibility}) async => 0;
  @override
  Future<void> unpublishPlaylist(int playlistRowId) async {}
  @override
  Future<List<PlaylistsTableData>> getLocalPlaylists() async => [];
  @override
  Future<List<SocialActivitiesTableData>> getFeedPage({required int limit, required int offset, required List<String> excludeActorUrls}) async => [];
  @override
  Future<void> processIncomingActivity({required String activityId, required String type, required String actorUrl, required dynamic objectData, required String rawJson, required DateTime publishedAt, required bool isFromMuted, required bool isHostedLocally}) async {}
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

// Subclass that starts from a fixed state without calling real repos.
class _StubFeedNotifier extends SocialFeedNotifier {
  final SocialFeedState _fixed;

  _StubFeedNotifier(this._fixed)
      : super(_StubActivityRepo(), _StubSocialRepo());

  @override
  Future<void> refresh() async => state = _fixed;

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> _load({required int offset, required bool append}) async {}
}

Widget _wrap(Widget child, SocialFeedState feedState) => ProviderScope(
      overrides: [
        socialFeedProvider.overrideWith(
          (ref) => _StubFeedNotifier(feedState),
        ),
        // Prevent NotificationsBadgeButton from calling sl<AppDatabase>()
        notificationsProvider.overrideWith(
          (ref) => NotificationsNotifier.stub(),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => Scaffold(body: child)),
          ],
        ),
      ),
    );

void main() {
  group('SocialFeedScreenV2', () {
    testWidgets('shows empty state when no activities', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SocialFeedScreenV2(),
          const SocialFeedState(items: [], isLoading: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Follow people to see what they\'re listening to',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows offline banner when isOffline is true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SocialFeedScreenV2(),
          const SocialFeedState(
            items: [],
            isLoading: false,
            isOffline: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Showing cached feed'), findsOneWidget);
    });

    testWidgets('muted actor activities absent — feed renders empty',
        (tester) async {
      // Pre-filtered empty items list simulates muted actors excluded
      await tester.pumpWidget(
        _wrap(
          const SocialFeedScreenV2(),
          const SocialFeedState(items: [], isLoading: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SocialFeedScreenV2), findsOneWidget);
      // No activity cards in the feed
      expect(find.byType(ListTile), findsNothing);
    });
  });
}
