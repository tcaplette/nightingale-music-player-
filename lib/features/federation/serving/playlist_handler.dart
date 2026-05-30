import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:nightingale/core/activitypub/models/ap_collection.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/logging/app_logger.dart';

const _tag = 'playlist_handler';

Future<Response> playlistHandler(
  Request request,
  String username,
  String playlistId,
) async {
  final db = sl<AppDatabase>();

  // Find the playlist by its collection URL suffix
  final playlists = await db.select(db.playlistsTable).get();
  final playlist = playlists.where((p) {
    final url = p.collectionUrl;
    return url != null && url.endsWith('/playlists/$playlistId');
  }).firstOrNull;

  if (playlist == null) {
    return Response.notFound('Not found');
  }

  // Private playlists are never served
  if (playlist.visibility == 'private') {
    return Response.notFound('Not found');
  }

  // Followers-only: verify requester is in the local followers collection
  if (playlist.visibility == 'followers') {
    final requesterUrl = _extractRequesterUrl(request);
    if (requesterUrl == null) {
      AppLogger.debug(
        'Playlist $playlistId: followers-only, no requester identity',
        tag: _tag,
      );
      return Response.forbidden('Forbidden');
    }

    final isFollower = await _isFollower(db, requesterUrl);
    if (!isFollower) {
      AppLogger.debug(
        'Playlist $playlistId: requester $requesterUrl is not a follower',
        tag: _tag,
      );
      return Response.forbidden('Forbidden');
    }
  }

  // Build OrderedCollection
  final trackIds = _parseTrackIds(playlist.trackIdsJson);
  final collection = ApOrderedCollection(
    id: playlist.collectionUrl!,
    totalItems: trackIds.length,
    orderedItems: trackIds.map((id) => {'type': 'Audio', 'id': id}).toList(),
  );

  return Response.ok(
    jsonEncode(collection.toJson()),
    headers: {HttpHeaders.contentTypeHeader: 'application/activity+json'},
  );
}

String? _extractRequesterUrl(Request request) {
  // Reuse the same stub as library_handler — HTTP Signature extraction
  // is wired at the middleware level (Phase 7 hardening).
  return null;
}

Future<bool> _isFollower(AppDatabase db, String actorUrl) async {
  final row = await (db.select(db.followersTable)
        ..where((t) => t.actorUrl.equals(actorUrl)))
      .getSingleOrNull();
  return row != null;
}

List<String> _parseTrackIds(String json) {
  try {
    return (jsonDecode(json) as List).cast<String>();
  } catch (_) {
    return [];
  }
}
