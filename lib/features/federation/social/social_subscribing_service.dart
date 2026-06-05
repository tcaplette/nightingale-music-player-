import 'package:drift/drift.dart';
import 'package:nightingale/core/activitypub/models/ap_activity.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/federation/nightingale_actor_validator.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/delivery/activity_delivery_service.dart';
import 'package:nightingale/features/federation/discovery/peer_exchange_service.dart';
import 'package:nightingale/features/federation/library/remote_library_fetcher.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

const _tag = 'social_subscribing';

/// Manages social relationships: following, followers, follow requests.
class SocialSubscribingService {
  SocialSubscribingService({
    required AppDatabase db,
    required ActorResolver actorResolver,
    required ActivityDeliveryService delivery,
    required NodeIdentityRepository identityRepo,
    required PeerExchangeService peerExchange,
    required RemoteLibraryFetcher libraryFetcher,
    required NightingaleActorValidator validator,
  })  : _db = db,
        _actorResolver = actorResolver,
        _delivery = delivery,
        _identityRepo = identityRepo,
        _peerExchange = peerExchange,
        _libraryFetcher = libraryFetcher,
        _validator = validator;

  final AppDatabase _db;
  final ActorResolver _actorResolver;
  final ActivityDeliveryService _delivery;
  final NodeIdentityRepository _identityRepo;
  final PeerExchangeService _peerExchange;
  final RemoteLibraryFetcher _libraryFetcher;
  final NightingaleActorValidator _validator;

  // ── Following ─────────────────────────────────────────────────────────────

  /// Sends a Follow activity to the target actor.
  Future<void> followActor(String actorUrl) async {
    // Check if already following
    final existing = await (_db.select(_db.followingTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .getSingleOrNull();

    if (existing != null) {
      AppLogger.info('Already following $actorUrl', tag: _tag);
      return;
    }

    // Resolve actor to verify existence and get inbox
    final result = await _actorResolver.resolve(actorUrl);
    if (result is! ResolveOk) {
      AppLogger.warning(
        'SocialSubscribingService: could not resolve $actorUrl ($result) — aborting follow',
        tag: _tag,
      );
      return;
    }
    final actor = result.actor;
    AppLogger.debug(
      'SocialSubscribingService: resolved actor id=${actor.id} '
      'nightingalePublicAddress=${actor.nightingalePublicAddress}',
      tag: _tag,
    );

    if (!_validator.isNightingalePeer(actor)) {
      AppLogger.warning(
        'SocialSubscribingService: $actorUrl is not a Nightingale peer — skipping follow '
        '(id=${actor.id} nightingalePublicAddress=${actor.nightingalePublicAddress})',
        tag: _tag,
      );
      return;
    }

    // Insert into following table
    await _db.into(_db.followingTable).insert(
          FollowingTableCompanion.insert(
            actorUrl: actorUrl,
            followedAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    AppLogger.info('Now following $actorUrl', tag: _tag);

    // Send Follow activity to target's inbox
    final myActorUrl = await _identityRepo.getActorUrl();
    final followActivity = ApFollow(
      id: '$myActorUrl/follow/${DateTime.now().millisecondsSinceEpoch}',
      actor: myActorUrl,
      object: actorUrl,
      published: DateTime.now(),
    );

    if (actor.inbox != null) {
      await _delivery.deliver(followActivity, actor.inbox!);
      AppLogger.info('Follow activity delivered to ${actor.inbox}', tag: _tag);
    }

    // Enqueue a peer exchange job so the new contact's social graph is fetched
    // and cached in the background. This is fire-and-forget — the follow
    // completes immediately and the UI is not blocked.
    _peerExchange.enqueue(actorUrl);

    // Immediately seed the local recommendation cache with the new peer's
    // library so the radio has tracks to play straight away.
    _libraryFetcher.fetchLibrary(actorUrl).then((tracks) {
      AppLogger.info(
        'Pre-seeded ${tracks?.length ?? 0} tracks from new follow $actorUrl',
        tag: _tag,
      );
    }).ignore();
  }

  /// Unfollows an actor.
  Future<void> unfollowActor(String actorUrl) async {
    await (_db.delete(_db.followingTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .go();

    AppLogger.info('Unfollowed $actorUrl', tag: _tag);

    // Send Undo(Follow) activity
    final myActorUrl = await _identityRepo.getActorUrl();
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

    // Try to deliver to the actor's inbox
    final result = await _actorResolver.resolve(actorUrl);
    if (result is ResolveOk && result.actor.inbox != null) {
      await _delivery.deliver(undoActivity, result.actor.inbox!);
    }
  }

  /// Returns true if we are following the given actor.
  Future<bool> isFollowing(String actorUrl) async {
    final row = await (_db.select(_db.followingTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .getSingleOrNull();
    return row != null;
  }

  /// Lists all actors we are following.
  Future<List<FollowingTableData>> getFollowing() async {
    return _db.select(_db.followingTable).get();
  }

  // ── Followers ─────────────────────────────────────────────────────────────

  /// Records a new follower (called when we receive an Accept activity
  /// in response to our Follow, or when someone follows us).
  Future<void> addFollower(String actorUrl) async {
    await _db.into(_db.followersTable).insert(
          FollowersTableCompanion.insert(
            actorUrl: actorUrl,
            followedAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    AppLogger.info('New follower: $actorUrl', tag: _tag);
  }

  /// Removes a follower.
  Future<void> removeFollower(String actorUrl) async {
    await (_db.delete(_db.followersTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .go();

    AppLogger.info('Removed follower: $actorUrl', tag: _tag);
  }

  /// Returns true if the given actor is following us.
  Future<bool> isFollower(String actorUrl) async {
    final row = await (_db.select(_db.followersTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .getSingleOrNull();
    return row != null;
  }

  /// Lists all our followers.
  Future<List<FollowersTableData>> getFollowers() async {
    return _db.select(_db.followersTable).get();
  }

  // ── Library Publishing Integration ────────────────────────────────────────

  /// Returns true if the given actor can view our library based on
  /// our sharing scope and their relationship to us.
  Future<bool> canViewLibrary({
    required String viewerActorUrl,
    required SharingScope scope,
  }) async {
    switch (scope) {
      case SharingScope.public:
        return true;
      case SharingScope.followersOnly:
        return await isFollower(viewerActorUrl);
      case SharingScope.private:
        return false;
    }
  }
}

enum SharingScope { public, followersOnly, private }
