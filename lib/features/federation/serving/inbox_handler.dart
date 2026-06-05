import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:nightingale/core/activitypub/activity_sanitizer.dart';
import 'package:nightingale/core/activitypub/activity_validator.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/features/federation/moderation/moderation_repository.dart';
import 'package:nightingale/features/federation/moderation/rate_limiter.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/core/repositories/activity_repository.dart';
import 'package:nightingale/core/repositories/social_repository.dart';
import 'package:nightingale/core/activitypub/models/ap_activity.dart' show ApPeerAddress, ApRelayRequest;
import 'package:nightingale/features/federation/delivery/circuit_relay_client.dart';
import 'package:nightingale/features/federation/nat/hole_punch_service.dart';
import 'package:nightingale/features/federation/social/social_subscribing_service.dart';

const _sanitizer = ActivitySanitizer();
const _validator = ActivityValidator();

Future<Response> inboxHandler(Request request, String username) async {
  final sourceDomain = request.requestedUri.host;

  // 1. Defederation check (fastest — DB read before any heavy work)
  final modRepo = sl<ModerationRepository>();
  if (await modRepo.isDefederated(sourceDomain)) {
    AppLogger.debug('Inbox: defederated node $sourceDomain', tag: 'inbox');
    return Response.forbidden('Forbidden');
  }

  // 2. Rate limit check
  final rateLimiter = sl<RateLimiter>();
  if (!rateLimiter.checkAndRecord(sourceDomain)) {
    AppLogger.debug('Inbox: rate limited $sourceDomain', tag: 'inbox');
    return Response(
      HttpStatus.tooManyRequests,
      body: 'Too many requests',
      headers: {'Retry-After': '60'},
    );
  }

  // 3. HTTP Signature verification
  final sigService = sl<HttpSignatureService>();
  final sigResult = await sigService.verifyRequest(request);
  if (sigResult is! SignatureVerified) {
    AppLogger.debug(
      'Inbox: signature ${sigResult.runtimeType} from $sourceDomain',
      tag: 'inbox',
    );
    return switch (sigResult) {
      SignatureMissing() => Response(HttpStatus.unauthorized, body: 'Unauthorized'),
      SignatureReplayed() => Response(HttpStatus.badRequest, body: 'Replayed request'),
      SignatureFailed() => Response(HttpStatus.unauthorized, body: 'Invalid signature'),
      _ => Response(HttpStatus.unauthorized, body: 'Unauthorized'),
    };
  }

  // 4. Read body (size limit already enforced by middleware for Content-Length;
  //    double-check here for chunked bodies).
  final body = await request.readAsString();
  if (body.length > 64 * 1024) {
    return Response(HttpStatus.requestEntityTooLarge, body: 'Payload too large');
  }

  // 5. Sanitize
  final sanitized = _sanitizer.sanitize(body);
  if (sanitized is SanitizerRejected) {
    AppLogger.debug(
      'Inbox: sanitizer rejected: ${sanitized.reason}',
      tag: 'inbox',
    );
    return Response(HttpStatus.badRequest, body: 'Bad request');
  }
  final json = (sanitized as SanitizerOk).json;

  // 6. Validate activity type
  final validated = _validator.validate(json);
  if (validated is ValidationDropped) {
    // Return 202 to avoid leaking capability information.
    AppLogger.debug(
      'Inbox: dropped activity: ${validated.reason}',
      tag: 'inbox',
    );
    return Response(HttpStatus.accepted);
  }

  final activity = (validated as ValidationOk).activity;

  // 7. Deduplication check
  final db = sl<AppDatabase>();
  final existing = await (db.select(db.inboxActivitiesTable)
        ..where((t) => t.activityId.equals(activity.id)))
      .getSingleOrNull();
  if (existing != null) {
    return Response(HttpStatus.accepted); // idempotent — already stored
  }

  // 8. Check block/mute state for social processing
  final socialRepo = sl<SocialRepository>();
  final isBlocked = await socialRepo.isBlocked(activity.actor);
  if (isBlocked) {
    // Discard all activities from blocked actors silently
    AppLogger.debug(
      'Inbox: dropped activity from blocked actor ${activity.actor}',
      tag: 'inbox',
    );
    return Response(HttpStatus.accepted);
  }
  final isMuted = await socialRepo.isMuted(activity.actor);

  // 9. Handle Follow activities (Phase 4 + Phase 5)
  if (activity.type == 'Follow') {
    // Phase 4 legacy path (library sync)
    final legacy = sl<SocialSubscribingService>();
    await legacy.addFollower(activity.actor);
    // Phase 5: social graph with manual-approval support
    await socialRepo.handleIncomingFollow(
      actorUrl: activity.actor,
      activityId: activity.id,
      manuallyApprovesFollowers: false, // default public; node identity prefs wired in Phase 7
    );
    AppLogger.info('Inbox: new follower ${activity.actor}', tag: 'inbox');
  }

  // 10. Handle Undo(Follow) activities (Phase 4 + Phase 5)
  if (activity.type == 'Undo' && activity.object is Map) {
    final obj = activity.object as Map;
    if (obj['type'] == 'Follow') {
      final legacy = sl<SocialSubscribingService>();
      await legacy.removeFollower(activity.actor);
      AppLogger.info('Inbox: removed follower ${activity.actor}', tag: 'inbox');
    }
  }

  // 11. Handle Accept / Reject (Phase 5 — follow request outcomes)
  if (activity.type == 'Accept' && activity.object is Map) {
    final obj = activity.object as Map;
    if (obj['type'] == 'Follow') {
      final followActivityId = obj['id'] as String?;
      if (followActivityId != null) {
        await socialRepo.handleIncomingAccept(followActivityId);
        AppLogger.info(
          'Inbox: Accept{Follow} from ${activity.actor}',
          tag: 'inbox',
        );
      }
    }
  }
  if (activity.type == 'Reject' && activity.object is Map) {
    final obj = activity.object as Map;
    if (obj['type'] == 'Follow') {
      final followActivityId = obj['id'] as String?;
      if (followActivityId != null) {
        await socialRepo.handleIncomingReject(followActivityId);
        AppLogger.info(
          'Inbox: Reject{Follow} from ${activity.actor}',
          tag: 'inbox',
        );
      }
    }
  }

  // 12. Handle Listen activities (Phase 4)
  if (activity.type == 'Listen') {
    final listenObject = activity.object;
    if (listenObject is Map) {
      await db.into(db.listenActivitiesTable).insert(
            ListenActivitiesTableCompanion.insert(
              actorUrl: activity.actor,
              trackId: listenObject['id']?.toString() ?? 'unknown',
              trackTitle: listenObject['name']?.toString() ?? 'Unknown',
              trackArtist:
                  listenObject['artist']?.toString() ?? 'Unknown Artist',
              listenedAt: Value(DateTime.now()),
              durationMs: const Value(0),
            ),
          );
      AppLogger.info('Inbox: stored Listen from ${activity.actor}', tag: 'inbox');
    }
  }

  // 13. Handle Like / Announce (Phase 5 — social activities)
  if (activity.type == 'Like' || activity.type == 'Announce') {
    final activityRepo = sl<ActivityRepository>();
    // Determine if the object is hosted locally (simple heuristic: check domain)
    final isHostedLocally = false; // wired properly in Phase 7 with identity URL check
    await activityRepo.processIncomingActivity(
      activityId: activity.id,
      type: activity.type,
      actorUrl: activity.actor,
      objectData: activity.object,
      rawJson: jsonEncode(json),
      publishedAt: activity.published ?? DateTime.now(),
      isFromMuted: isMuted,
      isHostedLocally: isHostedLocally,
    );
  }

  // 14. Route hole-punch and relay activities before storing.
  if (activity is ApPeerAddress) {
    sl<HolePunchService>().handleIncomingPeerAddress(activity);
  }
  if (activity is ApRelayRequest && activity.object is Map) {
    final obj = activity.object as Map;
    final sessionId = obj['sessionId'] as String?;
    final relayAddress = obj['relayAddress'] as String?;
    if (sessionId != null && relayAddress != null) {
      sl<CircuitRelayClient>()
          .connectAsRelayServer(
            sessionId: sessionId,
            relayAddress: relayAddress,
          )
          .ignore();
    }
  }

  // 15. Store
  await db.into(db.inboxActivitiesTable).insert(
        InboxActivitiesTableCompanion.insert(
          activityId: activity.id,
          type: activity.type,
          actorUrl: activity.actor,
          rawJson: jsonEncode(json),
          objectJson: Value(activity.object != null
              ? jsonEncode(activity.object)
              : null),
        ),
      );

  AppLogger.info(
    'Inbox: stored ${activity.type} from ${activity.actor}',
    tag: 'inbox',
  );
  return Response(HttpStatus.accepted);
}
