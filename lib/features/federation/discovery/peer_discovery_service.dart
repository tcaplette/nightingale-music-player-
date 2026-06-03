import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/activitypub/models/ap_collection.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/logging/app_logger.dart';

const _tag = 'peer_discovery';

/// Searches for Nightingale nodes by username across the resolution chain:
///
/// 1. Local actor cache — actors previously seen through any connection
/// 2. Live social graph traversal — fetch followers/following of all known
///    actors to find peers who were introduced indirectly
///
/// When Alice follows Bob, Bob's followers include Carol (different city).
/// Carol's actor URL and STUN address are fetched and cached. Next time
/// Alice searches for Carol, she's found locally.
class PeerDiscoveryService {
  PeerDiscoveryService({
    required AppDatabase db,
    required ActorResolver actorResolver,
  })  : _db = db,
        _actorResolver = actorResolver;

  final AppDatabase _db;
  final ActorResolver _actorResolver;

  /// Searches for actors matching [username] across all available sources.
  /// Returns as soon as a match is found; falls through each tier in order.
  Future<ApActor?> searchByUsername(String username) async {
    // 1. Local actor cache — actors seen through any previous interaction.
    final cached = await _searchCache(username);
    if (cached != null) {
      AppLogger.debug('Found $username in local actor cache', tag: _tag);
      return cached;
    }

    // 2. Live social graph traversal — check followers/following of every
    //    known actor. This reaches peers on different networks who were
    //    introduced through mutual connections.
    AppLogger.debug('Searching social graph for $username…', tag: _tag);
    return _traverseSocialGraph(username);
  }

  // ── Private ──────────────────────────────────────────────────────────────

  Future<ApActor?> _searchCache(String username) async {
    final rows = await _db.select(_db.actorCacheTable).get();
    for (final row in rows) {
      try {
        final json = jsonDecode(row.actorJson) as Map<String, dynamic>;
        if (json['preferredUsername'] == username) {
          return ApActor.fromJson(json);
        }
      } catch (_) {}
    }
    return null;
  }

  Future<ApActor?> _traverseSocialGraph(String username) async {
    final knownUrls = <String>{};

    final followers = await _db.select(_db.followersTable).get();
    final following = await _db.select(_db.followingTable).get();
    for (final r in followers) knownUrls.add(r.actorUrl);
    for (final r in following) knownUrls.add(r.actorUrl);

    for (final knownUrl in knownUrls) {
      final result = await _actorResolver.resolve(knownUrl);
      if (result is! ResolveOk) continue;
      final knownActor = result.actor;

      for (final collectionUrl in [knownActor.followers, knownActor.following]) {
        final found = await _searchCollection(collectionUrl, username);
        if (found != null) return found;
      }
    }

    return null;
  }

  Future<ApActor?> _searchCollection(
    String collectionUrl,
    String username,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(collectionUrl),
        headers: {'Accept': 'application/activity+json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final collection = ApOrderedCollection.fromJson(json);

      final items = collection.orderedItems;
      if (items != null) {
        for (final item in items) {
          final actorUrl = item is String ? item : item['id'] as String?;
          if (actorUrl == null) continue;
          final found = await _resolveIfUsername(actorUrl, username);
          if (found != null) return found;
        }
      }

      if (collection.first != null) {
        final pageResponse = await http.get(
          Uri.parse(collection.first!),
          headers: {'Accept': 'application/activity+json'},
        ).timeout(const Duration(seconds: 5));

        if (pageResponse.statusCode == 200) {
          final pageJson =
              jsonDecode(pageResponse.body) as Map<String, dynamic>;
          final page = ApOrderedCollectionPage.fromJson(pageJson);
          for (final item in page.orderedItems) {
            final actorUrl = item is String ? item : item['id'] as String?;
            if (actorUrl == null) continue;
            final found = await _resolveIfUsername(actorUrl, username);
            if (found != null) return found;
          }
        }
      }
    } catch (e) {
      AppLogger.debug('Collection fetch failed ($collectionUrl): $e', tag: _tag);
    }
    return null;
  }

  Future<ApActor?> _resolveIfUsername(
    String actorUrl,
    String username,
  ) async {
    try {
      final result = await _actorResolver.resolve(actorUrl);
      if (result is ResolveOk &&
          result.actor.preferredUsername == username) {
        return result.actor;
      }
    } catch (_) {}
    return null;
  }
}
