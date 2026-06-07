import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/activitypub/models/ap_audio.dart';
import 'package:nightingale/core/activitypub/models/ap_collection.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/nat/connection_negotiator.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:http/http.dart' as http;

const _tag = 'remote_library';

/// Fetches and parses remote library collections from federated nodes.
class RemoteLibraryFetcher {
  RemoteLibraryFetcher({
    required AppDatabase db,
    required ActorResolver actorResolver,
    required HttpSignatureService sigService,
    ConnectionNegotiator? connectionNegotiator,
  })  : _db = db,
        _actorResolver = actorResolver,
        _sigService = sigService,
        _connectionNegotiator = connectionNegotiator;

  final AppDatabase _db;
  final ActorResolver _actorResolver;
  final HttpSignatureService _sigService;
  final ConnectionNegotiator? _connectionNegotiator;

  /// Fetches a remote actor's library collection.
  /// Returns null if the library is private or we're not authorized.
  Future<List<TrackModel>?> fetchLibrary(String actorUrl) async {
    try {
      // Resolve the actor
      final result = await _actorResolver.resolve(actorUrl);
      if (result is! ResolveOk) {
        AppLogger.warning('Could not resolve actor: $actorUrl', tag: _tag);
        return null;
      }
      final actor = result.actor;

      // Resolve connection endpoint — falls back to direct address when
      // ConnectionNegotiator is not wired up.
      String baseUrl;
      if (_connectionNegotiator != null) {
        print('LIBRARY_FETCH: resolving endpoint for $actorUrl nightingalePublicAddress=${actor.nightingalePublicAddress}');
        final resolved = await _connectionNegotiator.resolveEndpoint(actorUrl);
        print('LIBRARY_FETCH: resolveEndpoint result=$resolved');
        if (resolved == null) {
          AppLogger.warning('No path to $actorUrl', tag: _tag);
          return null;
        }
        baseUrl = resolved;
      } else {
        baseUrl = _baseUrl(actor);
      }
      final libraryUrl = '$baseUrl/users/${actor.preferredUsername}/library';

      // Sign the request with HTTP Signature
      final request = http.Request('GET', Uri.parse(libraryUrl));
      request.headers['Accept'] = 'application/activity+json';
      final signedRequest = await _sigService.signRequest(request);

      // Send request
      final client = http.Client();
      final response = await client.send(signedRequest);
      final body = await response.stream.bytesToString();
      client.close();

      if (response.statusCode == 403) {
        AppLogger.info('Library access denied for $actorUrl', tag: _tag);
        return null;
      }

      if (response.statusCode != 200) {
        AppLogger.warning(
          'Library fetch failed: ${response.statusCode} for $libraryUrl',
          tag: _tag,
        );
        return null;
      }

      // Parse collection
      final json = jsonDecode(body) as Map<String, dynamic>;
      final collection = ApOrderedCollection.fromJson(json);

      // Fetch first page if available.
      // Resolve relative page URLs against the actor's transport base.
      List<TrackModel> tracks = [];
      if (collection.first != null) {
        final rawPageUrl = collection.first!;
        final pageUrl = Uri.tryParse(rawPageUrl)?.isAbsolute == true
            ? rawPageUrl
            : '$baseUrl$rawPageUrl';
        tracks = await _fetchCollectionPage(pageUrl, actorUrl);
      }

      await _saveToCache(actorUrl, tracks);
      AppLogger.info(
        'Cached ${tracks.length} tracks from $actorUrl',
        tag: _tag,
      );
      return tracks;
    } catch (e) {
      AppLogger.error('Failed to fetch library from $actorUrl', tag: _tag, error: e);
      return null;
    }
  }

  Future<void> _saveToCache(String actorUrl, List<TrackModel> tracks) async {
    final items = tracks.map((t) => {
      'name': t.title,
      'artist': t.artist,
      if (t.albumName != null) 'album': t.albumName,
      if (t.genre != null) 'genre': t.genre,
      'duration': t.durationMs ~/ 1000,
      if (t.streamUrl != null) 'stream_url': t.streamUrl,
      if (t.artworkPath != null) 'artwork_url': t.artworkPath,
    }).toList();

    await _db.into(_db.remoteLibrariesTable).insertOnConflictUpdate(
      RemoteLibrariesTableCompanion(
        actorUrl: Value(actorUrl),
        collectionJson: Value(jsonEncode({'items': items})),
        fetchedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Fetches a specific collection page.
  Future<List<TrackModel>> _fetchCollectionPage(String pageUrl, String sourceActorUrl) async {
    try {
      final request = http.Request('GET', Uri.parse(pageUrl));
      request.headers['Accept'] = 'application/activity+json';
      final signedRequest = await _sigService.signRequest(request);

      final client = http.Client();
      final response = await client.send(signedRequest);
      final body = await response.stream.bytesToString();
      client.close();

      if (response.statusCode != 200) return [];

      final json = jsonDecode(body) as Map<String, dynamic>;
      final page = ApOrderedCollectionPage.fromJson(json);

      return page.orderedItems.map((item) => _audioToTrack(item, sourceActorUrl)).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch collection page: $pageUrl', tag: _tag, error: e);
      return [];
    }
  }

  /// Returns the HTTP server base URL for [actor].
  /// Uses the STUN-discovered public address when available; falls back to
  /// stripping the user path from [ApActor.id].
  static String _baseUrl(ApActor actor) {
    if (actor.nightingalePublicAddress != null) {
      return 'http://${actor.nightingalePublicAddress}';
    }
    return actor.id.replaceAll('/users/${actor.preferredUsername}', '');
  }

  TrackModel _audioToTrack(Map<String, dynamic> json, String sourceActorUrl) {
    final audio = ApAudio.fromJson(json);
    // Extract track ID from the audio URL
    final trackIdStr = audio.id.split('/').last;
    final trackId = int.tryParse(trackIdStr) ?? 0;

    return TrackModel(
      id: trackId,
      filePath: audio.url ?? audio.id,
      title: audio.name ?? 'Unknown',
      artist: audio.artist ?? 'Unknown Artist',
      albumName: audio.album,
      durationMs: audio.duration?.inMilliseconds ?? 0,
      artworkPath: audio.artworkUrl,
      dateAdded: DateTime.now(),
      sourceActorUrl: sourceActorUrl,
      streamUrl: audio.url,
      isReachable: true,
    );
  }
}
