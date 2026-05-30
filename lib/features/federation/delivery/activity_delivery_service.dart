import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:nightingale/core/activitypub/models/ap_activity.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/delivery/relay_client.dart';
import 'package:nightingale/features/federation/moderation/moderation_repository.dart';

const _maxAttempts = 3;
const _retryDelays = [
  Duration(seconds: 5),
  Duration(seconds: 10),
  Duration(seconds: 20),
];

class ActivityDeliveryService {
  ActivityDeliveryService({
    required this.db,
    required this.sigService,
    required this.relayClient,
    required this.moderation,
  });

  final AppDatabase db;
  final HttpSignatureService sigService;
  final RelayClient relayClient;
  final ModerationRepository moderation;

  Future<void> deliver(ApActivity activity, String targetInboxUrl) async {
    // Check defederation before queueing
    final domain = Uri.parse(targetInboxUrl).host;
    if (await moderation.isDefederated(domain)) {
      AppLogger.debug(
        'Delivery suppressed (defederated): $domain',
        tag: 'delivery',
      );
      return;
    }

    // Write to outbox queue
    await db.into(db.outboxActivitiesTable).insert(
          OutboxActivitiesTableCompanion.insert(
            activityId: activity.id,
            type: activity.type,
            targetInboxUrl: targetInboxUrl,
            payloadJson: jsonEncode(activity.toJson()),
          ),
        );

    unawaited(_attemptDelivery(activity, targetInboxUrl));
  }

  /// Called on app startup to re-enqueue stale pending/retrying activities.
  Future<void> sweepPendingOnStartup() async {
    final stale = await (db.select(db.outboxActivitiesTable)
          ..where(
            (t) => t.status.isIn(['pending', 'retrying']),
          ))
        .get();

    for (final row in stale) {
      try {
        final json = jsonDecode(row.payloadJson) as Map<String, dynamic>;
        final activity = ApActivity.fromJson(json);
        unawaited(_attemptDelivery(activity, row.targetInboxUrl));
      } catch (e) {
        AppLogger.warning(
          'Sweep: could not re-enqueue ${row.activityId}: $e',
          tag: 'delivery',
        );
      }
    }
    AppLogger.info(
      'Delivery sweep: re-enqueued ${stale.length} activities',
      tag: 'delivery',
    );
  }

  Future<void> _attemptDelivery(
    ApActivity activity,
    String targetInboxUrl,
  ) async {
    var attempt = 0;
    while (attempt < _maxAttempts) {
      if (attempt > 0) {
        await Future.delayed(_retryDelays[attempt - 1]);
      }
      attempt++;

      await _updateStatus(activity.id, 'retrying', attempt);

      try {
        final req = http.Request('POST', Uri.parse(targetInboxUrl))
          ..headers['Content-Type'] = 'application/activity+json'
          ..body = jsonEncode(activity.toJson());

        final signed = await sigService.signRequest(req);
        final response = await http.Client()
            .send(signed)
            .then(http.Response.fromStream);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          await _updateStatus(activity.id, 'delivered', attempt);
          AppLogger.info(
            'Delivered ${activity.type} to $targetInboxUrl',
            tag: 'delivery',
          );
          return;
        }

        AppLogger.warning(
          'Attempt $attempt failed (${response.statusCode}) for ${activity.id}',
          tag: 'delivery',
        );
      } catch (e) {
        AppLogger.warning(
          'Attempt $attempt error for ${activity.id}: $e',
          tag: 'delivery',
        );
      }
    }

    // All direct attempts exhausted — hand to relay
    final refId = await relayClient.handOff(activity, targetInboxUrl);
    await _updateStatus(activity.id, 'relayed', attempt, relayRef: refId);
    AppLogger.info(
      'Handed ${activity.id} to relay (ref=$refId)',
      tag: 'delivery',
    );
  }

  Future<void> _updateStatus(
    String activityId,
    String status,
    int attempts, {
    String? relayRef,
  }) async {
    await (db.update(db.outboxActivitiesTable)
          ..where((t) => t.activityId.equals(activityId)))
        .write(OutboxActivitiesTableCompanion(
      status: Value(status),
      attemptCount: Value(attempts),
      lastAttemptedAt: Value(DateTime.now().toUtc()),
      relayReferenceId: relayRef != null ? Value(relayRef) : const Value.absent(),
    ));
  }
}
