import 'dart:async';

import 'package:drift/drift.dart';
import 'package:nightingale/core/activitypub/models/ap_activity.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/federation/nightingale_actor_validator.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/core/repositories/social_repository.dart';
import 'package:nightingale/features/federation/delivery/activity_delivery_service.dart';
import 'package:nightingale/features/federation/moderation/moderation_repository.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

const _tag = 'social_repo';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl({
    required AppDatabase db,
    required ActivityDeliveryService delivery,
    required ActorResolver actorResolver,
    required NodeIdentityRepository identityRepo,
    required ModerationRepository moderation,
    required NightingaleActorValidator validator,
  })  : _db = db,
        _delivery = delivery,
        _actorResolver = actorResolver,
        _identityRepo = identityRepo,
        _moderation = moderation,
        _validator = validator;

  final AppDatabase _db;
  final ActivityDeliveryService _delivery;
  final ActorResolver _actorResolver;
  final NodeIdentityRepository _identityRepo;
  final ModerationRepository _moderation;
  final NightingaleActorValidator _validator;

  // ── Outgoing follows ──────────────────────────────────────────────────────

  @override
  Future<FollowResult> followActor(String actorUrl, {String? mastodonHandle}) async {
    print('DEBUG_FOLLOW: followActor called actorUrl=$actorUrl mastodonHandle=$mastodonHandle');
    // Exact URL match first (fast path).
    final exactMatch = await (_db.select(_db.followsTable)
          ..where((t) => t.remoteActorUrl.equals(actorUrl)))
        .getSingleOrNull();
    if (exactMatch != null) {
      AppLogger.info('followActor: already following $actorUrl — skipping', tag: _tag);
      return AlreadyFollowing();
    }

    // Username match — same peer, different IP (actor URL changed on network change).
    // Extract the username from the path and check for an existing follow.
    final username = Uri.tryParse(actorUrl)
        ?.pathSegments
        .lastWhere((s) => s.isNotEmpty, orElse: () => '');
    if (username != null && username.isNotEmpty) {
      final usernameMatch = await (_db.select(_db.followsTable)
            ..where((t) => t.remoteActorUrl.like('%/users/$username')))
          .getSingleOrNull();
      if (usernameMatch != null) {
        // Update the stored URL to the current one and return.
        await (_db.update(_db.followsTable)
              ..where((t) => t.rowId.equals(usernameMatch.rowId)))
            .write(FollowsTableCompanion(
          remoteActorUrl: Value(actorUrl),
          // Only write handle if provided — don't overwrite an existing value with null.
          mastodonHandle: mastodonHandle != null
              ? Value(mastodonHandle)
              : const Value.absent(),
        ));
        await (_db.update(_db.followingTable)
              ..where((t) => t.actorUrl.like('%/users/$username')))
            .write(FollowingTableCompanion(actorUrl: Value(actorUrl)));
        AppLogger.info(
          'followActor: updated actor URL for $username ($actorUrl)',
          tag: _tag,
        );
        return AlreadyFollowing();
      }
    }

    final myActorUrl = await _identityRepo.getActorUrl();

    // Resolve actor to get inbox and privacy setting
    final resolved = await _actorResolver.resolve(actorUrl);
    AppLogger.debug('followActor: resolve($actorUrl) → ${resolved.runtimeType}', tag: _tag);
    if (resolved is ResolveOk) {
      final actor = resolved.actor;
      AppLogger.debug(
        'followActor: resolved actor id=${actor.id} '
        'nightingalePublicAddress=${actor.nightingalePublicAddress} '
        'inbox=${actor.inbox}',
        tag: _tag,
      );
      if (!_validator.isNightingalePeer(actor)) {
        AppLogger.warning(
          'followActor: $actorUrl rejected — not a Nightingale peer '
          '(id=${actor.id} nightingalePublicAddress=${actor.nightingalePublicAddress})',
          tag: _tag,
        );
        return NotANightingalePeer(actor);
      }
    } else {
      AppLogger.warning(
        'followActor: could not resolve $actorUrl ($resolved) — proceeding with pending_delivery state',
        tag: _tag,
      );
    }

    final inbox = resolved is ResolveOk ? (resolved.actor.inbox) : null;
    final manuallyApproves = resolved is ResolveOk
        ? (resolved.actor.manuallyApprovesFollowers ?? false)
        : false;

    // Determine initial state
    final initialState = inbox == null
        ? 'pending_delivery'
        : manuallyApproves
            ? 'pending'
            : 'accepted';

    final activityId =
        '$myActorUrl/follow/${DateTime.now().millisecondsSinceEpoch}';

    // Record in follow_requests (outgoing)
    await _db.into(_db.followRequestsTable).insert(
          FollowRequestsTableCompanion.insert(
            direction: 'outgoing',
            actorUrl: actorUrl,
            state: Value(initialState),
            activityId: Value(activityId),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    // If public and reachable, also add to follows as accepted
    if (initialState == 'accepted') {
      await _db.into(_db.followsTable).insert(
            FollowsTableCompanion.insert(
              localActorId: myActorUrl,
              remoteActorUrl: actorUrl,
              state: const Value('accepted'),
              mastodonHandle: Value(mastodonHandle),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      // Maintain Phase 4 following_table compatibility for library sync
      await _db.into(_db.followingTable).insert(
            FollowingTableCompanion.insert(
              actorUrl: actorUrl,
              followedAt: Value(DateTime.now()),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }

    // Dispatch signed Follow activity
    final followActivity = ApFollow(
      id: activityId,
      actor: myActorUrl,
      object: actorUrl,
      published: DateTime.now(),
    );

    if (inbox != null) {
      unawaited(_delivery.deliver(followActivity, inbox));
    }

    AppLogger.info('Follow sent to $actorUrl (state=$initialState)', tag: _tag);
    return FollowSuccess();
  }

  @override
  Future<void> unfollowActor(String actorUrl) async {
    final myActorUrl = await _identityRepo.getActorUrl();

    // Remove from follows and follow_requests (local state authoritative)
    await (_db.delete(_db.followsTable)
          ..where((t) => t.remoteActorUrl.equals(actorUrl)))
        .go();
    await (_db.delete(_db.followRequestsTable)
          ..where(
            (t) =>
                t.actorUrl.equals(actorUrl) &
                t.direction.equals('outgoing'),
          ))
        .go();
    // Remove from Phase 4 following_table
    await (_db.delete(_db.followingTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .go();

    // Dispatch Undo{Follow} best-effort
    final undoActivity = ApUndo(
      id: '$myActorUrl/undo/${DateTime.now().millisecondsSinceEpoch}',
      actor: myActorUrl,
      object: {
        'type': 'Follow',
        'actor': myActorUrl,
        'object': actorUrl,
      },
      published: DateTime.now(),
    );
    final resolved = await _actorResolver.resolve(actorUrl);
    if (resolved is ResolveOk) {
      unawaited(_delivery.deliver(undoActivity, resolved.actor.inbox));
    }

    AppLogger.info('Unfollowed $actorUrl', tag: _tag);
  }

  @override
  Future<String?> getFollowState(String actorUrl) async {
    // Check follows table first (accepted)
    final follow = await (_db.select(_db.followsTable)
          ..where((t) => t.remoteActorUrl.equals(actorUrl)))
        .getSingleOrNull();
    if (follow != null) return follow.state;

    // Check outgoing follow_requests (pending/pending_delivery)
    final req = await (_db.select(_db.followRequestsTable)
          ..where(
            (t) =>
                t.actorUrl.equals(actorUrl) &
                t.direction.equals('outgoing'),
          ))
        .getSingleOrNull();
    return req?.state;
  }

  @override
  Future<List<FollowsTableData>> getFollowing() =>
      _db.select(_db.followsTable).get();

  @override
  Future<List<FollowRequestsTableData>> getOutgoingPendingRequests() =>
      (_db.select(_db.followRequestsTable)
            ..where(
              (t) =>
                  t.direction.equals('outgoing') &
                  t.state.isIn(['pending', 'pending_delivery']),
            ))
          .get();

  // ── Incoming follows ──────────────────────────────────────────────────────

  @override
  Future<void> acceptFollowRequest(int requestRowId) async {
    final myActorUrl = await _identityRepo.getActorUrl();
    final req = await (_db.select(_db.followRequestsTable)
          ..where((t) => t.rowId.equals(requestRowId)))
        .getSingleOrNull();
    if (req == null) return;

    // Move to followers
    await _db.into(_db.followersTable).insert(
          FollowersTableCompanion.insert(
            actorUrl: req.actorUrl,
            followedAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    // Update state
    await (_db.update(_db.followRequestsTable)
          ..where((t) => t.rowId.equals(requestRowId)))
        .write(FollowRequestsTableCompanion(
      state: const Value('accepted'),
      updatedAt: Value(DateTime.now()),
    ));

    // Dispatch Accept{Follow}
    final acceptActivity = ApAccept(
      id: '$myActorUrl/accept/${DateTime.now().millisecondsSinceEpoch}',
      actor: myActorUrl,
      object: {'type': 'Follow', 'actor': req.actorUrl, 'object': myActorUrl},
      published: DateTime.now(),
    );
    final resolved = await _actorResolver.resolve(req.actorUrl);
    if (resolved is ResolveOk) {
      unawaited(_delivery.deliver(acceptActivity, resolved.actor.inbox));
    }

    // Write notification
    await _db.into(_db.notificationsTable).insert(
          NotificationsTableCompanion.insert(
            type: 'new_follower',
            fromActorUrl: req.actorUrl,
          ),
        );

    AppLogger.info('Accepted follow from ${req.actorUrl}', tag: _tag);
  }

  @override
  Future<void> rejectFollowRequest(int requestRowId) async {
    final myActorUrl = await _identityRepo.getActorUrl();
    final req = await (_db.select(_db.followRequestsTable)
          ..where((t) => t.rowId.equals(requestRowId)))
        .getSingleOrNull();
    if (req == null) return;

    await (_db.delete(_db.followRequestsTable)
          ..where((t) => t.rowId.equals(requestRowId)))
        .go();

    // Dispatch Reject{Follow}
    final rejectActivity = ApReject(
      id: '$myActorUrl/reject/${DateTime.now().millisecondsSinceEpoch}',
      actor: myActorUrl,
      object: {'type': 'Follow', 'actor': req.actorUrl, 'object': myActorUrl},
      published: DateTime.now(),
    );
    final resolved = await _actorResolver.resolve(req.actorUrl);
    if (resolved is ResolveOk) {
      unawaited(_delivery.deliver(rejectActivity, resolved.actor.inbox));
    }

    AppLogger.info('Rejected follow from ${req.actorUrl}', tag: _tag);
  }

  @override
  Future<List<FollowRequestsTableData>> getIncomingPendingRequests() =>
      (_db.select(_db.followRequestsTable)
            ..where(
              (t) =>
                  t.direction.equals('incoming') &
                  t.state.equals('pending_review'),
            ))
          .get();

  // ── Followers ─────────────────────────────────────────────────────────────

  @override
  Future<List<FollowersTableData>> getFollowers() =>
      _db.select(_db.followersTable).get();

  // ── Block ─────────────────────────────────────────────────────────────────

  @override
  Future<void> blockActor(String actorUrl) async {
    final myActorUrl = await _identityRepo.getActorUrl();

    // Record block
    await _db.into(_db.blocksTable).insert(
          BlocksTableCompanion.insert(actorUrl: actorUrl),
          mode: InsertMode.insertOrIgnore,
        );

    // Remove follow relationships in both directions
    await (_db.delete(_db.followsTable)
          ..where((t) => t.remoteActorUrl.equals(actorUrl)))
        .go();
    await (_db.delete(_db.followingTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .go();
    await (_db.delete(_db.followersTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .go();
    await (_db.delete(_db.followRequestsTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .go();

    // Dispatch Block activity
    final blockActivity = ApBlock(
      id: '$myActorUrl/block/${DateTime.now().millisecondsSinceEpoch}',
      actor: myActorUrl,
      object: actorUrl,
      published: DateTime.now(),
    );
    final resolved = await _actorResolver.resolve(actorUrl);
    if (resolved is ResolveOk) {
      unawaited(_delivery.deliver(blockActivity, resolved.actor.inbox));
    }

    AppLogger.info('Blocked $actorUrl', tag: _tag);
  }

  @override
  Future<void> unblockActor(String actorUrl) async {
    final myActorUrl = await _identityRepo.getActorUrl();

    await (_db.delete(_db.blocksTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .go();

    final undoActivity = ApUndo(
      id: '$myActorUrl/undo-block/${DateTime.now().millisecondsSinceEpoch}',
      actor: myActorUrl,
      object: {'type': 'Block', 'actor': myActorUrl, 'object': actorUrl},
      published: DateTime.now(),
    );
    final resolved = await _actorResolver.resolve(actorUrl);
    if (resolved is ResolveOk) {
      unawaited(_delivery.deliver(undoActivity, resolved.actor.inbox));
    }

    AppLogger.info('Unblocked $actorUrl', tag: _tag);
  }

  @override
  Future<bool> isBlocked(String actorUrl) async {
    final row = await (_db.select(_db.blocksTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<List<BlocksTableData>> getBlocks() =>
      _db.select(_db.blocksTable).get();

  // ── Mute ──────────────────────────────────────────────────────────────────

  @override
  Future<void> muteActor(String actorUrl) async {
    await _db.into(_db.mutesTable).insert(
          MutesTableCompanion.insert(actorUrl: actorUrl),
          mode: InsertMode.insertOrIgnore,
        );
    AppLogger.info('Muted $actorUrl (local only)', tag: _tag);
  }

  @override
  Future<void> unmuteActor(String actorUrl) async {
    await (_db.delete(_db.mutesTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .go();
    AppLogger.info('Unmuted $actorUrl', tag: _tag);
  }

  @override
  Future<bool> isMuted(String actorUrl) async {
    final row = await (_db.select(_db.mutesTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<List<MutesTableData>> getMutes() => _db.select(_db.mutesTable).get();

  // ── Inbox follow-request handling ─────────────────────────────────────────

  @override
  Future<void> handleIncomingFollow({
    required String actorUrl,
    required String activityId,
    required bool manuallyApprovesFollowers,
  }) async {
    final myActorUrl = await _identityRepo.getActorUrl();

    // Silently discard follows from blocked actors
    if (await isBlocked(actorUrl)) {
      AppLogger.debug(
        'Incoming Follow from blocked actor $actorUrl — discarded',
        tag: _tag,
      );
      return;
    }

    if (!manuallyApprovesFollowers) {
      // Public account: auto-accept
      await _db.into(_db.followersTable).insert(
            FollowersTableCompanion.insert(
              actorUrl: actorUrl,
              followedAt: Value(DateTime.now()),
            ),
            mode: InsertMode.insertOrIgnore,
          );

      // Write notification
      await _db.into(_db.notificationsTable).insert(
            NotificationsTableCompanion.insert(
              type: 'new_follower',
              fromActorUrl: actorUrl,
            ),
          );

      // Dispatch Accept{Follow}
      final acceptActivity = ApAccept(
        id: '$myActorUrl/accept/${DateTime.now().millisecondsSinceEpoch}',
        actor: myActorUrl,
        object: {'type': 'Follow', 'actor': actorUrl, 'object': myActorUrl},
        published: DateTime.now(),
      );
      final resolved = await _actorResolver.resolve(actorUrl);
      if (resolved is ResolveOk) {
        unawaited(_delivery.deliver(acceptActivity, resolved.actor.inbox));
      }

      AppLogger.info('Auto-accepted follow from $actorUrl', tag: _tag);
    } else {
      // Private account: queue for manual review
      await _db.into(_db.followRequestsTable).insert(
            FollowRequestsTableCompanion.insert(
              direction: 'incoming',
              actorUrl: actorUrl,
              state: const Value('pending_review'),
              activityId: Value(activityId),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      AppLogger.info(
        'Incoming follow from $actorUrl queued for review',
        tag: _tag,
      );
    }
  }

  @override
  Future<void> handleIncomingAccept(String originalActivityId) async {
    // Transition the outgoing follow_request to accepted
    final rows = await (_db.select(_db.followRequestsTable)
          ..where(
            (t) =>
                t.activityId.equals(originalActivityId) &
                t.direction.equals('outgoing'),
          ))
        .get();

    for (final row in rows) {
      final myActorUrl = await _identityRepo.getActorUrl();

      // Promote to follows
      await _db.into(_db.followsTable).insert(
            FollowsTableCompanion.insert(
              localActorId: myActorUrl,
              remoteActorUrl: row.actorUrl,
              state: const Value('accepted'),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      // Maintain Phase 4 library sync
      await _db.into(_db.followingTable).insert(
            FollowingTableCompanion.insert(
              actorUrl: row.actorUrl,
              followedAt: Value(DateTime.now()),
            ),
            mode: InsertMode.insertOrIgnore,
          );

      await (_db.update(_db.followRequestsTable)
            ..where((t) => t.rowId.equals(row.rowId)))
          .write(FollowRequestsTableCompanion(
        state: const Value('accepted'),
        updatedAt: Value(DateTime.now()),
      ));

      AppLogger.info('Follow accepted by ${row.actorUrl}', tag: _tag);
    }
  }

  @override
  Future<void> handleIncomingReject(String originalActivityId) async {
    final rows = await (_db.select(_db.followRequestsTable)
          ..where(
            (t) =>
                t.activityId.equals(originalActivityId) &
                t.direction.equals('outgoing'),
          ))
        .get();

    for (final row in rows) {
      await (_db.delete(_db.followRequestsTable)
            ..where((t) => t.rowId.equals(row.rowId)))
          .go();

      // Write a notification so the user knows the request was rejected
      await _db.into(_db.notificationsTable).insert(
            NotificationsTableCompanion.insert(
              type: 'follow_rejected',
              fromActorUrl: row.actorUrl,
            ),
          );

      AppLogger.info('Follow rejected by ${row.actorUrl}', tag: _tag);
    }
  }
}
