import 'dart:io';

import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/http_server/federation_server.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/delivery/relay_client.dart';
import 'package:nightingale/features/federation/reachability/node_reachability_service.dart';
import 'package:nightingale/features/federation/streaming/audio_cache_manager.dart';
import 'package:nightingale/features/library/models/track_model.dart';

const _tag = 'stream_resolver';

enum StreamPath { direct, relay, cache, unavailable }

class StreamResolution {
  const StreamResolution({
    required this.path,
    required this.url,
    this.error,
  });

  final StreamPath path;
  final String? url;
  final String? error;
}

/// Resolves federated track references to playable stream URLs.
class StreamResolver {
  StreamResolver({
    required ActorResolver actorResolver,
    required RelayClient relayClient,
    required NodeReachabilityService reachability,
    required AudioCacheManager cacheManager,
  })  : _actorResolver = actorResolver,
        _relayClient = relayClient,
        _reachability = reachability,
        _cacheManager = cacheManager;

  final ActorResolver _actorResolver;
  final RelayClient _relayClient;
  final NodeReachabilityService _reachability;
  final AudioCacheManager _cacheManager;

  /// Resolves a remote track to a stream URL using the fallback chain:
  /// direct → relay → cache → unavailable
  Future<StreamResolution> resolveRemoteTrack({
    required String actorUrl,
    required String trackId,
  }) async {
    // 1. Try direct stream
    final directUrl = await _tryDirectStream(actorUrl, trackId);
    if (directUrl != null) {
      AppLogger.info('StreamResolver: direct path available for $trackId', tag: _tag);
      return StreamResolution(path: StreamPath.direct, url: directUrl);
    }

    // 2. Try relay
    final relayUrl = await _tryRelayStream(actorUrl, trackId);
    if (relayUrl != null) {
      AppLogger.info('StreamResolver: relay path available for $trackId', tag: _tag);
      return StreamResolution(path: StreamPath.relay, url: relayUrl);
    }

    // 3. Check local cache
    final cachedPath = await _cacheManager.getCachedPath(trackId, actorUrl);
    if (cachedPath != null) {
      AppLogger.info(
        'StreamResolver: serving $trackId from local cache',
        tag: _tag,
      );
      return StreamResolution(path: StreamPath.cache, url: cachedPath);
    }

    AppLogger.warning('StreamResolver: no path available for $trackId', tag: _tag);
    return const StreamResolution(
      path: StreamPath.unavailable,
      url: null,
      error: 'Host unreachable and no cached copy available',
    );
  }

  Future<String?> _tryDirectStream(String actorUrl, String trackId) async {
    final isReachable = await _reachability.isReachable(actorUrl);
    if (!isReachable) return null;

    final result = await _actorResolver.resolve(actorUrl);
    if (result is! ResolveOk) return null;
    final actor = result.actor;

    // Construct stream URL from actor's base URL
    final baseUrl = actor.id.replaceAll('/users/${actor.preferredUsername}', '');
    return '$baseUrl/stream/$trackId';
  }

  Future<String?> _tryRelayStream(String actorUrl, String trackId) async {
    return await _relayClient.requestStreamForward(
      targetActorUrl: actorUrl,
      trackId: trackId,
    );
  }
}
