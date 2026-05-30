import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/repositories/activity_repository.dart';
import 'package:nightingale/core/repositories/social_repository.dart';

class ProfileState {
  const ProfileState({
    this.actor,
    this.followState,
    this.isBlocked = false,
    this.isMuted = false,
    this.recentActivities = const [],
    this.playlists = const [],
    this.isLoading = true,
    this.lastUpdated,
    this.isStale = false,
  });

  final ApActor? actor;
  final String? followState;
  final bool isBlocked;
  final bool isMuted;
  final List<SocialActivitiesTableData> recentActivities;
  final List<PlaylistsTableData> playlists;
  final bool isLoading;
  final DateTime? lastUpdated;
  // true when we rendered from cache and the remote node was unreachable
  final bool isStale;

  ProfileState copyWith({
    ApActor? actor,
    String? followState,
    bool? isBlocked,
    bool? isMuted,
    List<SocialActivitiesTableData>? recentActivities,
    List<PlaylistsTableData>? playlists,
    bool? isLoading,
    DateTime? lastUpdated,
    bool? isStale,
  }) =>
      ProfileState(
        actor: actor ?? this.actor,
        followState: followState ?? this.followState,
        isBlocked: isBlocked ?? this.isBlocked,
        isMuted: isMuted ?? this.isMuted,
        recentActivities: recentActivities ?? this.recentActivities,
        playlists: playlists ?? this.playlists,
        isLoading: isLoading ?? this.isLoading,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        isStale: isStale ?? this.isStale,
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier({
    required String actorUrl,
    required SocialRepository socialRepo,
    required ActivityRepository activityRepo,
    required ActorResolver actorResolver,
  })  : _actorUrl = actorUrl,
        _socialRepo = socialRepo,
        _activityRepo = activityRepo,
        _actorResolver = actorResolver,
        super(const ProfileState()) {
    load();
  }

  final String _actorUrl;
  final SocialRepository _socialRepo;
  final ActivityRepository _activityRepo;
  final ActorResolver _actorResolver;

  Future<void> load() async {
    // Render from cache immediately while we fetch
    final cached = await _actorResolver.resolve(_actorUrl);
    ApActor? actor;
    bool isStale = false;

    if (cached is ResolveOk) {
      actor = cached.actor;
    } else {
      isStale = true;
    }

    final followState = await _socialRepo.getFollowState(_actorUrl);
    final isBlocked = await _socialRepo.isBlocked(_actorUrl);
    final isMuted = await _socialRepo.isMuted(_actorUrl);

    // Recent activities from local store (last 10)
    final activities = await _activityRepo.getFeedPage(
      limit: 10,
      offset: 0,
      excludeActorUrls: [],
    );
    final actorActivities =
        activities.where((a) => a.actorUrl == _actorUrl).take(10).toList();

    state = ProfileState(
      actor: actor,
      followState: followState,
      isBlocked: isBlocked,
      isMuted: isMuted,
      recentActivities: actorActivities,
      playlists: const [],
      isLoading: false,
      lastUpdated: DateTime.now(),
      isStale: isStale,
    );
  }
}

// Family provider — one ProfileNotifier per actorUrl
final profileProvider = StateNotifierProvider.family<ProfileNotifier,
    ProfileState, String>(
  (ref, actorUrl) => ProfileNotifier(
    actorUrl: actorUrl,
    socialRepo: sl<SocialRepository>(),
    activityRepo: sl<ActivityRepository>(),
    actorResolver: sl<ActorResolver>(),
  ),
);
