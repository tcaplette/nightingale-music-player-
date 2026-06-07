import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/repositories/base_repository.dart';

sealed class FollowResult {}

class FollowSuccess extends FollowResult {}

class AlreadyFollowing extends FollowResult {}

class NotANightingalePeer extends FollowResult {
  NotANightingalePeer(this.actor);
  final ApActor actor;
}

enum FollowRequestDirection { incoming, outgoing }

enum FollowRequestState {
  pending,
  pendingReview,
  accepted,
  rejected,
  cancelled,
  pendingDelivery,
}

abstract interface class SocialRepository implements Repository {
  // ── Outgoing follows ──────────────────────────────────────────────────────

  Future<FollowResult> followActor(String actorUrl, {String? mastodonHandle});
  Future<void> unfollowActor(String actorUrl);

  Future<String?> getFollowState(String actorUrl);

  Future<List<FollowsTableData>> getFollowing();
  Future<List<FollowRequestsTableData>> getOutgoingPendingRequests();

  // ── Incoming follows ──────────────────────────────────────────────────────

  Future<void> acceptFollowRequest(int requestRowId);
  Future<void> rejectFollowRequest(int requestRowId);

  Future<List<FollowRequestsTableData>> getIncomingPendingRequests();

  // ── Followers ─────────────────────────────────────────────────────────────

  Future<List<FollowersTableData>> getFollowers();

  // ── Block ─────────────────────────────────────────────────────────────────

  Future<void> blockActor(String actorUrl);
  Future<void> unblockActor(String actorUrl);
  Future<bool> isBlocked(String actorUrl);
  Future<List<BlocksTableData>> getBlocks();

  // ── Mute ──────────────────────────────────────────────────────────────────

  Future<void> muteActor(String actorUrl);
  Future<void> unmuteActor(String actorUrl);
  Future<bool> isMuted(String actorUrl);
  Future<List<MutesTableData>> getMutes();

  // ── Inbox follow-request handling (called from inbox processor) ───────────

  Future<void> handleIncomingFollow({
    required String actorUrl,
    required String activityId,
    required bool manuallyApprovesFollowers,
  });

  Future<void> handleIncomingAccept(String originalActivityId);
  Future<void> handleIncomingReject(String originalActivityId);
}
