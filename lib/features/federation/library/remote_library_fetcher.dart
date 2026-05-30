import 'dart:convert';

import 'package:nightingale/core/activitypub/models/ap_audio.dart';
import 'package:nightingale/core/activitypub/models/ap_collection.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/social/social_subscribing_service.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:http/http.dart' as http;

const _tag = 'remote_library';

/// Fetches and parses remote library collections from federated nodes.
class RemoteLibraryFetcher {
  RemoteLibraryFetcher({
    required ActorResolver actorResolver,
    required HttpSignatureService sigService,
    required SocialSubscribingService social,
  })  : _actorResolver = actorResolver,
        _sigService = sigService,
        _social = social;

  final ActorResolver _actorResolver;
  final HttpSignatureService _sigService;
  final SocialSubscribingService _social;

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

      // Construct library URL
      final libraryUrl = '${actor.id}/library';

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

      // Fetch first page if available
      if (collection.first != null) {
        return await _fetchCollectionPage(collection.first!, actorUrl);
      }

      return [];
    } catch (e) {
      AppLogger.error('Failed to fetch library from $actorUrl', tag: _tag, error: e);
      return null;
    }
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
