import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/features/discover/presentation/discover_screen.dart';
import 'package:nightingale/features/library/screens/album_detail_screen.dart';
import 'package:nightingale/features/library/screens/artist_detail_screen.dart';
import 'package:nightingale/features/library/screens/library_screen.dart';
import 'package:nightingale/features/library/screens/search_screen.dart';
import 'package:nightingale/features/node_identity/node_identity_notifier.dart';
import 'package:nightingale/features/onboarding/onboarding_notifier.dart';
import 'package:nightingale/features/onboarding/screens/onboarding_shell.dart';
import 'package:nightingale/features/player_ui/player_shell.dart';
import 'package:nightingale/features/player_ui/screens/now_playing_screen.dart';
import 'package:nightingale/features/player_ui/screens/queue_screen.dart';
import 'package:nightingale/features/social/screens/find_people_screen.dart';
import 'package:nightingale/features/social/screens/followers_screen.dart';
import 'package:nightingale/features/social/screens/following_screen.dart';
import 'package:nightingale/features/social/screens/notifications_screen.dart';
import 'package:nightingale/features/social/screens/playlist_detail_screen.dart';
import 'package:nightingale/features/social/screens/profile_screen.dart';
import 'package:nightingale/features/social/screens/social_feed_screen_v2.dart';
import 'package:nightingale/shared/components/navigation/app_bottom_nav.dart';
import 'package:nightingale/shared/theme/app_motion.dart';

abstract final class AppRoutes {
  static const String library = '/library';
  static const String albumDetail = '/library/albums/:albumId';
  static const String artistDetail = '/library/artists/:artistId';
  static const String search = '/search';
  static const String nowPlaying = '/now-playing';
  static const String queue = '/queue';
  // Phase 7 — onboarding (replaces the standalone identitySetup route)
  static const String onboarding = '/onboarding';
  // Kept for deep-link compatibility; onboarding flow handles identity creation
  static const String identitySetup = '/setup/identity';
  // Phase 5 — social routes
  static const String feed = '/feed';
  // Phase 6 — discovery
  static const String discover = '/discover';
  static const String notifications = '/notifications';
  static const String profile = '/profile/:actorId';
  static const String findPeople = '/social/find';
  static const String following = '/social/following';
  static const String followers = '/social/followers';
  static const String playlistDetail = '/playlists/:playlistId';
}

/// Reusable fade-through page builder. All top-level routes use this
/// to apply [AppMotion.pageTransition] duration and [AppMotion.curvePageTransition].
Page<T> _fadePage<T>(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.pageTransition,
    reverseTransitionDuration: AppMotion.pageTransition,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: AppMotion.curvePageTransition,
          ),
          child: child,
        ),
  );
}

/// Global router instance. Created once; redirect reads identity and onboarding
/// state via [ProviderScope.containerOf].
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.library,
  redirect: (context, state) {
    developer.log('ROUTER: redirect called for ${state.matchedLocation}', name: 'nightingale.router');
    final container = ProviderScope.containerOf(context);

    // Phase 7 onboarding guard — takes priority.
    final onboardingState = container.read(onboardingProvider);
    developer.log('ROUTER: onboardingState = ${onboardingState.runtimeType}', name: 'nightingale.router');
    final isOnboardingRoute = state.matchedLocation.startsWith(AppRoutes.onboarding);
    if (onboardingState is OnboardingRequired && !isOnboardingRoute) {
      developer.log('ROUTER: redirecting to onboarding', name: 'nightingale.router');
      return AppRoutes.onboarding;
    }
    if (onboardingState is OnboardingComplete && isOnboardingRoute) {
      developer.log('ROUTER: redirecting to library (onboarding done)', name: 'nightingale.router');
      return AppRoutes.library;
    }
    // While checking, allow the current route to stand (don't flash a redirect).
    if (onboardingState is OnboardingChecking) {
      developer.log('ROUTER: onboarding checking — no redirect', name: 'nightingale.router');
      return null;
    }

    // Legacy identity-setup guard (kept for deep-link edge cases).
    final identityState = container.read(nodeIdentityProvider);
    developer.log('ROUTER: identityState = ${identityState.runtimeType}', name: 'nightingale.router');
    final isSetupRoute = state.matchedLocation == AppRoutes.identitySetup;
    if (identityState is NodeIdentityMissing && !isSetupRoute && !isOnboardingRoute) {
      developer.log('ROUTER: redirecting to onboarding (no identity)', name: 'nightingale.router');
      return AppRoutes.onboarding;
    }
    if (identityState is NodeIdentityReady && isSetupRoute) {
      developer.log('ROUTER: redirecting to library', name: 'nightingale.router');
      return AppRoutes.library;
    }
    developer.log('ROUTER: no redirect', name: 'nightingale.router');
    return null;
  },
  routes: [
    // Phase 7 — onboarding shell (multi-step flow)
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      pageBuilder: (ctx, state) => _fadePage(ctx, state, const OnboardingShell()),
    ),
    // Legacy identity-setup route (kept for compatibility)
    GoRoute(
      path: AppRoutes.identitySetup,
      name: 'identitySetup',
      pageBuilder: (ctx, state) => _fadePage(ctx, state, const OnboardingShell()),
    ),
    // Main shell: PlayerShell + bottom nav wrapping the three primary tabs.
    // StatefulShellRoute preserves each branch's navigator stack independently.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => PlayerShell(
        child: AppBottomNav(
          navigationShell: navigationShell,
          child: navigationShell,
        ),
      ),
      branches: [
        // Branch 0 — Library
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.library,
              name: 'library',
              pageBuilder: (ctx, state) => _fadePage(ctx, state, const LibraryScreen()),
              routes: [
                GoRoute(
                  path: 'albums/:albumId',
                  name: 'albumDetail',
                  pageBuilder: (ctx, state) {
                    final albumId = int.parse(state.pathParameters['albumId']!);
                    return _fadePage(ctx, state, AlbumDetailScreen(albumId: albumId));
                  },
                ),
                GoRoute(
                  path: 'artists/:artistId',
                  name: 'artistDetail',
                  pageBuilder: (ctx, state) {
                    final artistName =
                        Uri.decodeComponent(state.pathParameters['artistId']!);
                    return _fadePage(ctx, state, ArtistDetailScreen(artistName: artistName));
                  },
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.search,
              name: 'search',
              pageBuilder: (ctx, state) => _fadePage(ctx, state, const SearchScreen()),
            ),
          ],
        ),
        // Branch 1 — Feed
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.feed,
              name: 'feed',
              pageBuilder: (ctx, state) => _fadePage(ctx, state, const SocialFeedScreenV2()),
            ),
          ],
        ),
        // Branch 2 — Discover
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.discover,
              name: 'discover',
              pageBuilder: (ctx, state) => _fadePage(ctx, state, const DiscoverScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.nowPlaying,
      name: 'nowPlaying',
      pageBuilder: (ctx, state) => _fadePage(ctx, state, const NowPlayingScreen()),
    ),
    GoRoute(
      path: AppRoutes.queue,
      name: 'queue',
      pageBuilder: (ctx, state) => _fadePage(ctx, state, const QueueScreen()),
    ),
    // Phase 5 — social routes (pushed over any branch)
    GoRoute(
      path: AppRoutes.notifications,
      name: 'notifications',
      pageBuilder: (ctx, state) => _fadePage(ctx, state, const NotificationsScreen()),
    ),
    GoRoute(
      path: AppRoutes.profile,
      name: 'profile',
      pageBuilder: (ctx, state) {
        final actorId =
            Uri.decodeComponent(state.pathParameters['actorId'] ?? '');
        return _fadePage(ctx, state, ProfileScreen(actorUrl: actorId));
      },
    ),
    GoRoute(
      path: AppRoutes.findPeople,
      name: 'findPeople',
      pageBuilder: (ctx, state) => _fadePage(ctx, state, const FindPeopleScreen()),
    ),
    GoRoute(
      path: AppRoutes.following,
      name: 'following',
      pageBuilder: (ctx, state) => _fadePage(ctx, state, const FollowingScreen()),
    ),
    GoRoute(
      path: AppRoutes.followers,
      name: 'followers',
      pageBuilder: (ctx, state) => _fadePage(ctx, state, const FollowersScreen()),
    ),
    GoRoute(
      path: AppRoutes.playlistDetail,
      name: 'playlistDetail',
      pageBuilder: (ctx, state) {
        final playlistId =
            Uri.decodeComponent(state.pathParameters['playlistId'] ?? '');
        return _fadePage(ctx, state, PlaylistDetailScreen(playlistUrl: playlistId));
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page not found',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
  ),
);
