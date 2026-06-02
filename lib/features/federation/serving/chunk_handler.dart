import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/publishing/library_publisher.dart';
import 'package:nightingale/features/federation/streaming/chunk_cache_manager.dart';
import 'package:nightingale/features/federation/streaming/seeding_power_policy.dart';

const _tag = 'chunk_handler';

Future<Response> chunkHandler(Request request, String hash) async {
  final sigService = sl<HttpSignatureService>();
  final libraryPublisher = sl<LibraryPublisher>();
  final chunkCache = sl<ChunkCacheManager>();
  final seedingPolicy = sl<SeedingPowerPolicy>();

  // ── Power policy ─────────────────────────────────────────────────────────
  if (!await seedingPolicy.canSeed()) {
    AppLogger.debug(
      'Chunk request denied by power policy for hash=$hash',
      tag: _tag,
    );
    return Response(
      503,
      headers: {'Retry-After': '60'},
      body: 'Seeding paused',
    );
  }

  // ── HTTP Signature Verification ──────────────────────────────────────────
  final sigResult = await sigService.verifyRequest(request);
  String? requesterActorUrl;

  switch (sigResult) {
    case SignatureVerified():
      final sigHeader = request.headers['signature'] ?? '';
      final keyIdMatch = RegExp(r'keyId="([^"]+)"').firstMatch(sigHeader);
      if (keyIdMatch != null) {
        requesterActorUrl = keyIdMatch.group(1)!.split('#').first;
      }
      AppLogger.debug('Chunk request verified from $requesterActorUrl',
          tag: _tag);
    case SignatureMissing():
      AppLogger.debug('Chunk request anonymous', tag: _tag);
    case SignatureFailed(:final reason):
      AppLogger.warning('Chunk signature failed: $reason', tag: _tag);
      return Response.forbidden('Invalid signature: $reason');
    case SignatureReplayed(:final nonce):
      AppLogger.warning('Replay detected: nonce=$nonce', tag: _tag);
      return Response.forbidden('Replay detected');
  }

  // ── Privacy / scope check ─────────────────────────────────────────────────
  final scope = libraryPublisher.sharingScope;
  if (scope == SharingScope.private) {
    return Response.forbidden('Library is private');
  }

  if (scope == SharingScope.followersOnly) {
    if (requesterActorUrl == null) {
      return Response.forbidden(
          'Authentication required for followers-only content');
    }
    final isFollower = await libraryPublisher.isFollower(requesterActorUrl);
    if (!isFollower) {
      return Response.forbidden('Not a follower');
    }
  }

  // ── Serve chunk ───────────────────────────────────────────────────────────
  final hashBytes = _hexToBytes(hash);
  if (hashBytes == null) {
    return Response.badRequest(body: 'Invalid hash format');
  }

  final data = await chunkCache.readChunk(hashBytes);
  if (data == null) {
    AppLogger.debug('Chunk not found: $hash', tag: _tag);
    return Response.notFound('Chunk not found');
  }

  AppLogger.debug(
    'Serving chunk $hash (${data.length} bytes) to $requesterActorUrl',
    tag: _tag,
  );

  return Response.ok(
    data,
    headers: {
      'Content-Type': 'application/octet-stream',
      'Content-Length': data.length.toString(),
    },
  );
}

Uint8List? _hexToBytes(String hex) {
  if (hex.length != 64 || !RegExp(r'^[0-9a-f]+$').hasMatch(hex)) return null;
  final result = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}
