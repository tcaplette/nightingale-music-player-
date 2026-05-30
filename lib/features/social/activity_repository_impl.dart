import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nightingale/core/activitypub/models/ap_activity.dart';
import 'package:nightingale/core/activitypub/models/ap_collection.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/core/repositories/activity_repository.dart';
import 'package:nightingale/features/federation/delivery/activity_delivery_service.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

const _tag = 'activity_repo';

class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl({
    required AppDatabase db,
    required ActivityDeliveryService delivery,
    required NodeIdentityRepository identityRepo,
    required String nodeBaseUrl,
  })  : _db = db,
        _delivery = delivery,
        _identityRepo = identityRepo,
        _nodeBaseUrl = nodeBaseUrl;

  final AppDatabase _db;
  final ActivityDeliveryService _delivery;
  final NodeIdentityRepository _identityRepo;
  final String _nodeBaseUrl;

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<List<String>> _followerInboxes() async {
    final followers = await _db.select(_db.followersTable).get();
    // For inbox delivery, we use the actorUrl as a proxy to find their inbox.
    // In production this would be resolved; for now return actor URLs as stubs
    // and let the delivery service handle resolution.
    return followers.map((f) => '${f.actorUrl}/inbox').toList();
  }

  String _activityId(String suffix) =>
      '$_nodeBaseUrl/activities/$suffix-${DateTime.now().millisecondsSinceEpoch}';

  // ── Now Playing ───────────────────────────────────────────────────────────

  @override
  Future<void> emitNowPlaying({
    required String trackId,
    required String trackTitle,
    required String trackArtist,
    required String hostingNodeUrl,
  }) async {
    final myActorUrl = await _identityRepo.getActorUrl();
    final activity = ApListen(
      id: _activityId('listen'),
      actor: myActorUrl,
      object: {
        'type': 'Audio',
        'id': trackId,
        'name': trackTitle,
        'artist': trackArtist,
        'attributedTo': hostingNodeUrl,
      },
      published: DateTime.now(),
    );

    final inboxes = await _followerInboxes();
    for (final inbox in inboxes) {
      unawaited(_delivery.deliver(activity, inbox));
    }

    AppLogger.debug(
      'Now Playing emitted: $trackTitle (${inboxes.length} recipients)',
      tag: _tag,
    );
  }

  // ── Like / Unlike ─────────────────────────────────────────────────────────

  @override
  Future<void> likeTrack({
    required String trackId,
    required String hostingNodeInbox,
  }) async {
    final myActorUrl = await _identityRepo.getActorUrl();
    final activity = ApLike(
      id: _activityId('like'),
      actor: myActorUrl,
      object: trackId,
      published: DateTime.now(),
    );

    // Store locally
    await _db.into(_db.socialActivitiesTable).insert(
          SocialActivitiesTableCompanion.insert(
            activityId: activity.id,
            type: 'Like',
            actorUrl: myActorUrl,
            objectJson: Value(trackId),
            rawJson: jsonEncode(activity.toJson()),
            publishedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    unawaited(_delivery.deliver(activity, hostingNodeInbox));
    AppLogger.debug('Liked $trackId', tag: _tag);
  }

  @override
  Future<void> unlikeTrack({
    required String trackId,
    required String hostingNodeInbox,
  }) async {
    final myActorUrl = await _identityRepo.getActorUrl();
    final undoActivity = ApUndo(
      id: _activityId('unlike'),
      actor: myActorUrl,
      object: {'type': 'Like', 'actor': myActorUrl, 'object': trackId},
      published: DateTime.now(),
    );

    // Remove local like record
    await (_db.delete(_db.socialActivitiesTable)
          ..where(
            (t) =>
                t.type.equals('Like') &
                t.actorUrl.equals(myActorUrl) &
                t.objectJson.equals(trackId),
          ))
        .go();

    unawaited(_delivery.deliver(undoActivity, hostingNodeInbox));
    AppLogger.debug('Unliked $trackId', tag: _tag);
  }

  @override
  Future<bool> isLiked(String trackId) async {
    final myActorUrl = await _identityRepo.getActorUrl();
    final row = await (_db.select(_db.socialActivitiesTable)
          ..where(
            (t) =>
                t.type.equals('Like') &
                t.actorUrl.equals(myActorUrl) &
                t.objectJson.equals(trackId),
          ))
        .getSingleOrNull();
    return row != null;
  }

  // ── Share (Announce) ──────────────────────────────────────────────────────

  @override
  Future<void> shareTrack({
    required String trackObjectUrl,
    required String trackTitle,
    required String trackArtist,
  }) async {
    final myActorUrl = await _identityRepo.getActorUrl();
    final activity = ApAnnounce(
      id: _activityId('announce'),
      actor: myActorUrl,
      object: {
        'type': 'Audio',
        'id': trackObjectUrl,
        'name': trackTitle,
        'artist': trackArtist,
      },
      published: DateTime.now(),
    );

    final inboxes = await _followerInboxes();
    for (final inbox in inboxes) {
      unawaited(_delivery.deliver(activity, inbox));
    }
    AppLogger.debug('Shared track $trackTitle', tag: _tag);
  }

  @override
  Future<void> sharePlaylist(String playlistCollectionUrl) async {
    final myActorUrl = await _identityRepo.getActorUrl();
    final activity = ApAnnounce(
      id: _activityId('announce-playlist'),
      actor: myActorUrl,
      object: playlistCollectionUrl,
      published: DateTime.now(),
    );

    final inboxes = await _followerInboxes();
    for (final inbox in inboxes) {
      unawaited(_delivery.deliver(activity, inbox));
    }
    AppLogger.debug('Shared playlist $playlistCollectionUrl', tag: _tag);
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  @override
  Future<void> saveTrack({
    required String trackId,
    required String trackTitle,
    required String trackArtist,
    required String hostingNodeUrl,
  }) async {
    // Store in social_activities as a Save record (metadata only, no download)
    final myActorUrl = await _identityRepo.getActorUrl();
    final activityId = _activityId('save');
    final objectJson = jsonEncode({
      'id': trackId,
      'name': trackTitle,
      'artist': trackArtist,
      'attributedTo': hostingNodeUrl,
    });

    await _db.into(_db.socialActivitiesTable).insert(
          SocialActivitiesTableCompanion.insert(
            activityId: activityId,
            type: 'Save',
            actorUrl: myActorUrl,
            objectJson: Value(objectJson),
            rawJson: objectJson,
            publishedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    AppLogger.debug('Saved track $trackTitle', tag: _tag);
  }

  // ── Playlist publish ──────────────────────────────────────────────────────

  @override
  Future<int> publishPlaylist({
    required String title,
    required List<String> trackIds,
    required String visibility,
  }) async {
    final myActorUrl = await _identityRepo.getActorUrl();
    final playlistId = DateTime.now().millisecondsSinceEpoch.toString();
    final collectionUrl =
        '$_nodeBaseUrl/users/node/playlists/$playlistId';

    // Write to DB
    final rowId = await _db.into(_db.playlistsTable).insertReturning(
          PlaylistsTableCompanion.insert(
            title: title,
            visibility: Value(visibility),
            collectionUrl: Value(collectionUrl),
            trackIdsJson: Value(jsonEncode(trackIds)),
          ),
        );

    if (visibility != 'private') {
      // Build OrderedCollection
      final collection = ApOrderedCollection(
        id: collectionUrl,
        totalItems: trackIds.length,
        orderedItems: trackIds.map((id) => {'type': 'Audio', 'id': id}).toList(),
      );

      // Dispatch Create{OrderedCollection} to followers
      final createActivity = ApCreate(
        id: _activityId('create-playlist'),
        actor: myActorUrl,
        object: collection.toJson(),
        published: DateTime.now(),
      );
      final inboxes = await _followerInboxes();
      for (final inbox in inboxes) {
        unawaited(_delivery.deliver(createActivity, inbox));
      }
    }

    AppLogger.info('Published playlist "$title" (rowId=${rowId.rowId})', tag: _tag);
    return rowId.rowId;
  }

  @override
  Future<void> unpublishPlaylist(int playlistRowId) async {
    final myActorUrl = await _identityRepo.getActorUrl();
    final playlist = await (_db.select(_db.playlistsTable)
          ..where((t) => t.rowId.equals(playlistRowId)))
        .getSingleOrNull();
    if (playlist == null) return;

    // Update visibility to private and clear URL
    await (_db.update(_db.playlistsTable)
          ..where((t) => t.rowId.equals(playlistRowId)))
        .write(PlaylistsTableCompanion(
      visibility: const Value('private'),
      collectionUrl: const Value(null),
      updatedAt: Value(DateTime.now()),
    ));

    // Dispatch Delete{OrderedCollection} if previously published
    if (playlist.collectionUrl != null) {
      final deleteActivity = ApDelete(
        id: _activityId('delete-playlist'),
        actor: myActorUrl,
        object: playlist.collectionUrl,
        published: DateTime.now(),
      );
      final inboxes = await _followerInboxes();
      for (final inbox in inboxes) {
        unawaited(_delivery.deliver(deleteActivity, inbox));
      }
    }

    AppLogger.info('Unpublished playlist rowId=$playlistRowId', tag: _tag);
  }

  @override
  Future<List<PlaylistsTableData>> getLocalPlaylists() =>
      _db.select(_db.playlistsTable).get();

  // ── Feed query ────────────────────────────────────────────────────────────

  @override
  Future<List<SocialActivitiesTableData>> getFeedPage({
    required int limit,
    required int offset,
    required List<String> excludeActorUrls,
  }) async {
    final query = _db.select(_db.socialActivitiesTable)
      ..orderBy([(t) => OrderingTerm.desc(t.publishedAt)])
      ..limit(limit, offset: offset);

    if (excludeActorUrls.isNotEmpty) {
      query.where((t) => t.actorUrl.isNotIn(excludeActorUrls));
    }

    return query.get();
  }

  // ── Incoming activity processing ──────────────────────────────────────────

  @override
  Future<void> processIncomingActivity({
    required String activityId,
    required String type,
    required String actorUrl,
    required dynamic objectData,
    required String rawJson,
    required DateTime publishedAt,
    required bool isFromMuted,
    required bool isHostedLocally,
  }) async {
    // Store in social_activities for feed (muted actors stored but not surfaced)
    await _db.into(_db.socialActivitiesTable).insert(
          SocialActivitiesTableCompanion.insert(
            activityId: activityId,
            type: type,
            actorUrl: actorUrl,
            objectJson: Value(
              objectData != null ? jsonEncode(objectData) : null,
            ),
            rawJson: rawJson,
            publishedAt: publishedAt,
          ),
          mode: InsertMode.insertOrIgnore,
        );

    // Write notifications for events directed at the local user (not for muted)
    if (!isFromMuted && isHostedLocally) {
      String? notifType;
      if (type == 'Like') notifType = 'like';
      if (type == 'Announce') notifType = 'announce';

      if (notifType != null) {
        final objRef =
            objectData != null ? jsonEncode(objectData) : null;
        await _db.into(_db.notificationsTable).insert(
              NotificationsTableCompanion.insert(
                type: notifType,
                fromActorUrl: actorUrl,
                objectRef: Value(objRef),
              ),
            );
      }
    }

    AppLogger.debug(
      'Processed incoming $type from $actorUrl (muted=$isFromMuted)',
      tag: _tag,
    );
  }
}
