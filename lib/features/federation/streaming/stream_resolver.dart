import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/nat/connection_negotiator.dart';
import 'package:nightingale/features/federation/reachability/node_reachability_service.dart';
import 'package:nightingale/features/federation/streaming/audio_cache_manager.dart';
import 'package:nightingale/features/federation/streaming/chunk_cache_manager.dart';
import 'package:nightingale/features/federation/streaming/chunk_manifest.dart';

const _tag = 'stream_resolver';

enum StreamPath { direct, cache, chunk, unavailable }

class StreamResolution {
  const StreamResolution({
    required this.path,
    this.url,
    this.assemblerManifest,
    this.error,
  });

  final StreamPath path;

  /// Populated for [StreamPath.direct] and [StreamPath.cache].
  final String? url;

  /// Populated for [StreamPath.chunk] — callers build a [ChunkStreamAssembler]
  /// from this manifest.
  final ChunkManifest? assemblerManifest;

  final String? error;
}

/// Resolves federated track references to playable stream URLs.
///
/// Fallback chain:
///   1. Chunk manifest (all chunks present locally)          → StreamPath.chunk
///   2. Chunk manifest (some missing) → fetch from peer then → StreamPath.chunk
///   3. Direct HTTP stream from source node                  → StreamPath.direct
///   4. Legacy whole-file local cache                        → StreamPath.cache
///   5. Unavailable                                          → StreamPath.unavailable
class StreamResolver {
  StreamResolver({
    required ActorResolver actorResolver,
    required NodeReachabilityService reachability,
    required AudioCacheManager cacheManager,
    ChunkCacheManager? chunkCacheManager,
    ChunkManifestRepository? manifestRepository,
    HttpSignatureService? sigService,
    ConnectionNegotiator? connectionNegotiator,
  })  : _actorResolver = actorResolver,
        _reachability = reachability,
        _cacheManager = cacheManager,
        _chunkCache = chunkCacheManager,
        _manifests = manifestRepository,
        _sigService = sigService,
        _connectionNegotiator = connectionNegotiator;

  final ActorResolver _actorResolver;
  final NodeReachabilityService _reachability;
  final AudioCacheManager _cacheManager;
  final ChunkCacheManager? _chunkCache;
  final ChunkManifestRepository? _manifests;
  final HttpSignatureService? _sigService;
  final ConnectionNegotiator? _connectionNegotiator;

  Future<StreamResolution> resolveRemoteTrack({
    required String actorUrl,
    required String trackId,
  }) async {
    AppLogger.info(
      'StreamResolver: resolving track=$trackId actor=$actorUrl',
      tag: _tag,
    );
    final trackIdInt = int.tryParse(trackId);

    // ── 1 & 2. Chunk path ────────────────────────────────────────────────────
    if (_manifests != null && _chunkCache != null && trackIdInt != null) {
      final manifest = await _manifests.getManifest(trackIdInt, actorUrl);
      if (manifest == null) {
        AppLogger.info(
          'StreamResolver: no chunk manifest for $trackId – skipping chunk path',
          tag: _tag,
        );
      }
      if (manifest != null) {
        final missingHashes = await _missingChunks(manifest);

        if (missingHashes.isEmpty) {
          AppLogger.info(
            'StreamResolver: all chunks cached for $trackId',
            tag: _tag,
          );
          return StreamResolution(
            path: StreamPath.chunk,
            assemblerManifest: manifest,
          );
        }

        // Try fetching missing chunks from the source node.
        final fetched = await _fetchMissingChunks(
          manifest: manifest,
          missingHashes: missingHashes,
          actorUrl: actorUrl,
        );
        if (fetched) {
          AppLogger.info(
            'StreamResolver: fetched missing chunks for $trackId',
            tag: _tag,
          );
          return StreamResolution(
            path: StreamPath.chunk,
            assemblerManifest: manifest,
          );
        }

        AppLogger.warning(
          'StreamResolver: could not fetch all missing chunks for $trackId; '
          'falling back to direct stream',
          tag: _tag,
        );
      }
    }

    // ── 3. Direct stream ─────────────────────────────────────────────────────
    final directUrl = await _tryDirectStream(actorUrl, trackId);
    if (directUrl != null) {
      AppLogger.info('StreamResolver: direct path for $trackId', tag: _tag);
      return StreamResolution(path: StreamPath.direct, url: directUrl);
    }

    // ── 4. Legacy whole-file cache ────────────────────────────────────────────
    final cachedPath = await _cacheManager.getCachedPath(trackId, actorUrl);
    if (cachedPath != null) {
      AppLogger.info(
        'StreamResolver: serving $trackId from local cache',
        tag: _tag,
      );
      return StreamResolution(path: StreamPath.cache, url: cachedPath);
    }

    AppLogger.warning(
      'StreamResolver: no path available for $trackId',
      tag: _tag,
    );
    return const StreamResolution(
      path: StreamPath.unavailable,
      error: 'Host unreachable and no cached copy available',
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<String?> _tryDirectStream(String actorUrl, String trackId) async {
    // If a ConnectionNegotiator is available, use it for three-tier resolution.
    if (_connectionNegotiator != null) {
      final baseUrl = await _connectionNegotiator.resolveEndpoint(actorUrl);
      if (baseUrl == null) {
        AppLogger.warning(
          'StreamResolver: ConnectionNegotiator found no path for $actorUrl',
          tag: _tag,
        );
        return null;
      }
      final url = '$baseUrl/stream/$trackId';
      AppLogger.info('StreamResolver: negotiated stream URL → $url', tag: _tag);
      return url;
    }

    // Fallback: legacy direct probe.
    final result = await _actorResolver.resolve(actorUrl);
    if (result is! ResolveOk) {
      AppLogger.warning(
        'StreamResolver: actor resolve failed for $actorUrl ($result) – cannot direct stream $trackId',
        tag: _tag,
      );
      return null;
    }
    final actor = result.actor;

    final isReachable = await _reachability.isReachable(
      actorUrl,
      publicAddress: actor.nightingalePublicAddress,
    );
    if (!isReachable) {
      AppLogger.warning(
        'StreamResolver: $actorUrl is unreachable – cannot direct stream $trackId',
        tag: _tag,
      );
      return null;
    }

    final url = '${_baseUrl(actor)}/stream/$trackId';
    AppLogger.info('StreamResolver: direct stream URL → $url', tag: _tag);
    return url;
  }

  Future<List<String>> _missingChunks(ChunkManifest manifest) async {
    final missing = <String>[];
    for (final hex in manifest.chunkHashes) {
      final raw = _hexToBytes(hex);
      final data = await _chunkCache!.readChunk(raw);
      if (data == null) missing.add(hex);
    }
    return missing;
  }

  Future<bool> _fetchMissingChunks({
    required ChunkManifest manifest,
    required List<String> missingHashes,
    required String actorUrl,
  }) async {
    String? baseUrl;
    if (_connectionNegotiator != null) {
      baseUrl = await _connectionNegotiator.resolveEndpoint(actorUrl);
    } else {
      final result = await _actorResolver.resolve(actorUrl);
      if (result is! ResolveOk) return false;
      final actor = result.actor;
      final isReachable = await _reachability.isReachable(
        actorUrl,
        publicAddress: actor.nightingalePublicAddress,
      );
      if (!isReachable) return false;
      baseUrl = _baseUrl(actor);
    }
    if (baseUrl == null) return false;

    for (final hex in missingHashes) {
      final chunkUrl = '$baseUrl/chunks/$hex';
      final request = http.Request('GET', Uri.parse(chunkUrl));

      http.Request signedRequest;
      if (_sigService != null) {
        signedRequest = await _sigService.signRequest(request);
      } else {
        signedRequest = request;
      }

      try {
        final client = http.Client();
        final streamedResponse = await client.send(signedRequest);

        if (streamedResponse.statusCode == 503) {
          // Peer is conserving resources — abort peer fetching, fall back to
          // direct stream.
          AppLogger.info(
            'StreamResolver: peer returned 503 for chunk $hex — '
            'falling back',
            tag: _tag,
          );
          client.close();
          return false;
        }

        if (streamedResponse.statusCode != 200) {
          client.close();
          return false;
        }

        final bytes = Uint8List.fromList(
          await streamedResponse.stream.toBytes(),
        );
        await _chunkCache!.writeChunk(_hexToBytes(hex), bytes);
        client.close();

        AppLogger.debug(
          'StreamResolver: fetched chunk $hex (${bytes.length} bytes)',
          tag: _tag,
        );
      } catch (e) {
        AppLogger.warning(
          'StreamResolver: failed to fetch chunk $hex: $e',
          tag: _tag,
        );
        return false;
      }
    }

    return true;
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

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}
