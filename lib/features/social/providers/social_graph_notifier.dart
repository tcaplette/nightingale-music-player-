import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/core/repositories/social_repository.dart';
export 'package:nightingale/core/repositories/social_repository.dart' show FollowResult, FollowSuccess, AlreadyFollowing, NotANightingalePeer;
import 'package:nightingale/features/federation/library/remote_library_fetcher.dart';

class SocialGraphState {
  const SocialGraphState({
    this.following = const [],
    this.followers = const [],
    this.outgoingPending = const [],
    this.incomingPending = const [],
    this.blocks = const [],
    this.mutes = const [],
    this.isLoading = false,
  });

  final List<FollowsTableData> following;
  final List<FollowersTableData> followers;
  final List<FollowRequestsTableData> outgoingPending;
  final List<FollowRequestsTableData> incomingPending;
  final List<BlocksTableData> blocks;
  final List<MutesTableData> mutes;
  final bool isLoading;

  SocialGraphState copyWith({
    List<FollowsTableData>? following,
    List<FollowersTableData>? followers,
    List<FollowRequestsTableData>? outgoingPending,
    List<FollowRequestsTableData>? incomingPending,
    List<BlocksTableData>? blocks,
    List<MutesTableData>? mutes,
    bool? isLoading,
  }) =>
      SocialGraphState(
        following: following ?? this.following,
        followers: followers ?? this.followers,
        outgoingPending: outgoingPending ?? this.outgoingPending,
        incomingPending: incomingPending ?? this.incomingPending,
        blocks: blocks ?? this.blocks,
        mutes: mutes ?? this.mutes,
        isLoading: isLoading ?? this.isLoading,
      );
}

class SocialGraphNotifier extends StateNotifier<SocialGraphState> {
  SocialGraphNotifier(this._repo) : super(const SocialGraphState()) {
    load();
  }

  final SocialRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final results = await Future.wait([
      _repo.getFollowing(),
      _repo.getFollowers(),
      _repo.getOutgoingPendingRequests(),
      _repo.getIncomingPendingRequests(),
      _repo.getBlocks(),
      _repo.getMutes(),
    ]);
    state = SocialGraphState(
      following: results[0] as List<FollowsTableData>,
      followers: results[1] as List<FollowersTableData>,
      outgoingPending: results[2] as List<FollowRequestsTableData>,
      incomingPending: results[3] as List<FollowRequestsTableData>,
      blocks: results[4] as List<BlocksTableData>,
      mutes: results[5] as List<MutesTableData>,
      isLoading: false,
    );
  }

  Future<FollowResult> followActor(String actorUrl) async {
    AppLogger.info('SocialGraph: followActor($actorUrl) — calling repository', tag: 'social_graph');
    final result = await _repo.followActor(actorUrl);
    AppLogger.info(
      'SocialGraph: followActor($actorUrl) → ${result.runtimeType}',
      tag: 'social_graph',
    );
    if (result is FollowSuccess) {
      // Seed the local recommendation cache immediately so the radio has tracks
      // without waiting for the next periodic refresh.
      sl<RemoteLibraryFetcher>().fetchLibrary(actorUrl).then((tracks) {
        AppLogger.info(
          'SocialGraph: pre-seeded ${tracks?.length ?? 0} tracks from new follow $actorUrl',
          tag: 'social_graph',
        );
      }).ignore();
    } else if (result is NotANightingalePeer) {
      AppLogger.warning(
        'SocialGraph: $actorUrl rejected — not a Nightingale peer '
        '(id=${result.actor.id} nightingalePublicAddress=${result.actor.nightingalePublicAddress})',
        tag: 'social_graph',
      );
    } else if (result is AlreadyFollowing) {
      AppLogger.info('SocialGraph: already following $actorUrl', tag: 'social_graph');
    }
    await load();
    return result;
  }

  Future<void> unfollowActor(String actorUrl) async {
    await _repo.unfollowActor(actorUrl);
    await load();
  }

  Future<String?> getFollowState(String actorUrl) =>
      _repo.getFollowState(actorUrl);

  Future<void> acceptFollowRequest(int requestRowId) async {
    await _repo.acceptFollowRequest(requestRowId);
    await load();
  }

  Future<void> rejectFollowRequest(int requestRowId) async {
    await _repo.rejectFollowRequest(requestRowId);
    await load();
  }

  Future<void> blockActor(String actorUrl) async {
    await _repo.blockActor(actorUrl);
    await load();
  }

  Future<void> unblockActor(String actorUrl) async {
    await _repo.unblockActor(actorUrl);
    await load();
  }

  Future<void> muteActor(String actorUrl) async {
    await _repo.muteActor(actorUrl);
    await load();
  }

  Future<void> unmuteActor(String actorUrl) async {
    await _repo.unmuteActor(actorUrl);
    await load();
  }

  Future<bool> isBlocked(String actorUrl) => _repo.isBlocked(actorUrl);
  Future<bool> isMuted(String actorUrl) => _repo.isMuted(actorUrl);
}

final socialGraphProvider =
    StateNotifierProvider<SocialGraphNotifier, SocialGraphState>(
  (ref) => SocialGraphNotifier(sl<SocialRepository>()),
);

// Cache-only actor lookup by URL — no network calls.
// Returns null if the actor has never been resolved or the cache entry is missing.
final cachedActorProvider =
    FutureProvider.family<ApActor?, String>((ref, actorUrl) async {
  final db = sl<AppDatabase>();
  final row = await (db.select(db.actorCacheTable)
        ..where((t) => t.actorUrl.equals(actorUrl)))
      .getSingleOrNull();
  if (row == null) return null;
  try {
    return ApActor.fromJson(
      jsonDecode(row.actorJson) as Map<String, dynamic>,
    );
  } catch (_) {
    return null;
  }
});
