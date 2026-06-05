import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/publishing/library_publisher.dart';
import 'package:nightingale/features/library/library_repository.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

const _tag = 'stream_handler';

Future<Response> streamHandler(Request request, String trackId) async {
  final sigService = sl<HttpSignatureService>();
  final libraryPublisher = sl<LibraryPublisher>();
  final identityRepo = sl<NodeIdentityRepository>();
  final libraryRepo = sl<LibraryRepository>();

  // ── HTTP Signature Verification ──────────────────────────────────────────
  final sigResult = await sigService.verifyRequest(request);
  String? requesterActorUrl;

  switch (sigResult) {
    case SignatureVerified():
      // Extract requester from keyId (format: actorUrl#main-key)
      final sigHeader = request.headers['signature'] ?? '';
      final keyIdMatch = RegExp(r'keyId="([^"]+)"').firstMatch(sigHeader);
      if (keyIdMatch != null) {
        requesterActorUrl = keyIdMatch.group(1)!.split('#').first;
      }
      AppLogger.debug('Stream request verified from $requesterActorUrl', tag: _tag);
    case SignatureMissing():
      // Anonymous requests are allowed for public streams
      AppLogger.debug('Stream request has no signature (anonymous)', tag: _tag);
    case SignatureFailed(:final reason):
      AppLogger.warning(
        'Stream signature verification failed: $reason from ${request.requestedUri}',
        tag: _tag,
      );
      // Log for moderation/debug (Task 7.4)
      await _logAuthFailure(request, 'signature_failed: $reason');
      return Response.forbidden('Invalid signature: $reason');
    case SignatureReplayed(:final nonce):
      AppLogger.warning('Replay attack detected: nonce=$nonce', tag: _tag);
      await _logAuthFailure(request, 'replay_detected: nonce=$nonce');
      return Response.forbidden('Replay detected');
  }

  // ── Privacy Check ────────────────────────────────────────────────────────
  final scope = libraryPublisher.sharingScope;
  AppLogger.info(
    'Stream: request trackId=$trackId scope=${scope.name} requester=${requesterActorUrl ?? "anonymous"}',
    tag: _tag,
  );
  if (scope == SharingScope.private) {
    return Response.forbidden('Library is private');
  }

  if (scope == SharingScope.followersOnly) {
    if (requesterActorUrl == null) {
      await _logAuthFailure(request, 'followers_only_no_auth');
      return Response.forbidden('Authentication required for followers-only content');
    }
    final isFollower = await libraryPublisher.isFollower(requesterActorUrl);
    if (!isFollower) {
      AppLogger.info('Stream denied: $requesterActorUrl is not a follower', tag: _tag);
      await _logAuthFailure(request, 'not_follower: $requesterActorUrl');
      return Response.forbidden('Not a follower');
    }
  }

  // ── Serve Track ──────────────────────────────────────────────────────────
  final trackIdInt = int.tryParse(trackId);
  if (trackIdInt == null) {
    return Response.badRequest(body: 'Invalid track ID');
  }

  final tracks = await libraryRepo.getAllTracks();
  final track = tracks.where((t) => t.id == trackIdInt).firstOrNull;
  if (track == null) {
    return Response.notFound('Track not found');
  }

  final file = File(track.filePath);
  if (!file.existsSync()) {
    AppLogger.error('Track file not found: ${track.filePath}', tag: _tag);
    return Response.notFound('Audio file not found');
  }
  AppLogger.info(
    'Stream: serving "${track.title}" by ${track.artist} (${file.lengthSync()} bytes) range=${request.headers['range'] ?? "full"}',
    tag: _tag,
  );

  // Handle range requests for seeking
  final rangeHeader = request.headers['range'];
  if (rangeHeader != null) {
    return _serveRange(file, rangeHeader);
  }

  // Full file
  return Response.ok(
    file.openRead(),
    headers: {
      HttpHeaders.contentTypeHeader: 'audio/mpeg',
      HttpHeaders.contentLengthHeader: file.lengthSync().toString(),
      'Accept-Ranges': 'bytes',
    },
  );
}

Future<Response> _serveRange(File file, String rangeHeader) async {
  final totalLength = file.lengthSync();
  final range = _parseRange(rangeHeader, totalLength);
  if (range == null) {
    return Response(
      HttpStatus.requestedRangeNotSatisfiable,
      headers: {'Content-Range': 'bytes */$totalLength'},
    );
  }

  final (start, end) = range;
  final contentLength = end - start + 1;

  return Response(
    HttpStatus.partialContent,
    body: file.openRead(start, end + 1),
    headers: {
      HttpHeaders.contentTypeHeader: 'audio/mpeg',
      HttpHeaders.contentLengthHeader: contentLength.toString(),
      'Content-Range': 'bytes $start-$end/$totalLength',
      'Accept-Ranges': 'bytes',
    },
  );
}

(int start, int end)? _parseRange(String rangeHeader, int totalLength) {
  // Expected format: "bytes=start-end"
  if (!rangeHeader.startsWith('bytes=')) return null;
  final rangeSpec = rangeHeader.substring(6);
  final parts = rangeSpec.split('-');
  if (parts.length != 2) return null;

  final start = int.tryParse(parts[0]);
  if (start == null || start >= totalLength) return null;

  final end = parts[1].isEmpty ? totalLength - 1 : int.tryParse(parts[1]);
  if (end == null || end < start || end >= totalLength) return null;

  return (start, end);
}

/// Logs authentication failures for moderation and debug purposes.
Future<void> _logAuthFailure(Request request, String reason) async {
  AppLogger.info(
    'Stream auth failure: $reason | '
    'path=${request.requestedUri.path} | '
    'remote=${request.context['shelf.io.connection_info'] ?? 'unknown'}',
    tag: 'stream_auth_failure',
  );
}
