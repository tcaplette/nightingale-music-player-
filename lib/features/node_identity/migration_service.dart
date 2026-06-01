import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:nightingale/core/activitypub/models/ap_activity.dart';
import 'package:nightingale/core/crypto/crypto_service.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/delivery/activity_delivery_service.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

const _tokenTtlHours = 72;

sealed class MigrationTokenResult {}

class MigrationTokenOk extends MigrationTokenResult {
  MigrationTokenOk(this.token);
  final String token;
}

class MigrationTokenError extends MigrationTokenResult {
  MigrationTokenError(this.reason);
  final String reason;
}

sealed class MoveResult {}

class MoveOk extends MoveResult {}

class MoveError extends MoveResult {
  MoveError(this.reason);
  final String reason;
}

class MigrationService {
  MigrationService({
    required this.db,
    required this.crypto,
    required this.identityRepo,
    required this.delivery,
  });

  final AppDatabase db;
  final CryptoService crypto;
  final NodeIdentityRepository identityRepo;
  final ActivityDeliveryService delivery;

  /// Exports a signed migration token (base64-encoded JSON payload + signature).
  Future<MigrationTokenResult> exportToken() async {
    try {
      final actor = await identityRepo.getLocalActor();
      final avatarBytes = await identityRepo.getAvatarBytes();
      final issuedAt = DateTime.now().toUtc().millisecondsSinceEpoch;
      final payloadMap = <String, dynamic>{
        'actorUrl': actor.id,
        'displayName': actor.name,
        'preferredUsername': actor.preferredUsername,
        'issuedAt': issuedAt,
        if (actor.summary != null) 'summary': actor.summary,
        if (avatarBytes != null) 'avatarJpeg': base64.encode(avatarBytes),
      };
      final payload = jsonEncode(payloadMap);
      final sigBytes = await crypto.sign(utf8.encode(payload));
      final token = base64Url.encode(
        utf8.encode(jsonEncode({
          'payload': payload,
          'signature': base64.encode(sigBytes),
        })),
      );
      AppLogger.info('Migration token exported for ${actor.id}', tag: 'migration');
      return MigrationTokenOk(token);
    } catch (e) {
      return MigrationTokenError('Failed to export token: $e');
    }
  }

  /// Validates a migration token and broadcasts a Move activity to followers.
  Future<MoveResult> initiateMove({
    required String migrationToken,
    required String newActorUrl,
  }) async {
    // Decode and parse token
    final Map<String, dynamic> outer;
    try {
      outer = jsonDecode(utf8.decode(base64Url.decode(migrationToken)))
          as Map<String, dynamic>;
    } catch (_) {
      return MoveError('Invalid token format');
    }

    final payload = outer['payload'] as String?;
    if (payload == null) return MoveError('Malformed token');

    final Map<String, dynamic> payloadJson;
    try {
      payloadJson = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return MoveError('Malformed token payload');
    }

    // Time check
    final issuedAt = payloadJson['issuedAt'] as int?;
    if (issuedAt == null) return MoveError('Missing issuedAt');
    final age = DateTime.now().toUtc().millisecondsSinceEpoch - issuedAt;
    if (age > Duration(hours: _tokenTtlHours).inMilliseconds) {
      return MoveError('Token expired (issued ${age ~/ 3600000}h ago)');
    }

    // Reuse check
    final tokenHash = sha256.convert(utf8.encode(migrationToken)).toString();
    final existing = await (db.select(db.migrationTokensTable)
          ..where((t) => t.tokenHash.equals(tokenHash)))
        .getSingleOrNull();
    if (existing != null && existing.usedAt != null) {
      return MoveError('Token already used');
    }

    // Restore profile fields from the token (graceful degradation for old tokens).
    final displayName = payloadJson['displayName'] as String?;
    final summary = payloadJson['summary'] as String?;
    final avatarJpegB64 = payloadJson['avatarJpeg'] as String?;
    if (displayName != null) {
      final avatarBytes =
          avatarJpegB64 != null ? base64.decode(avatarJpegB64) : null;
      await identityRepo.updateProfile(
        displayName: displayName,
        summary: summary,
        avatarBytes: avatarBytes,
      );
    }

    // Broadcast Move activity to each follower
    final oldActorUrl = payloadJson['actorUrl'] as String?;
    if (oldActorUrl == null) return MoveError('Missing actorUrl in token');

    final followers =
        await db.select(db.followersTable).get();
    final moveActivity = ApMove(
      id: '$oldActorUrl#move-${DateTime.now().millisecondsSinceEpoch}',
      actor: oldActorUrl,
      object: oldActorUrl,
      target: newActorUrl,
      to: ['https://www.w3.org/ns/activitystreams#Public'],
    );

    for (final follower in followers) {
      await delivery.deliver(moveActivity, '${follower.actorUrl}/inbox');
    }

    // Mark token as used
    await db.into(db.migrationTokensTable).insertOnConflictUpdate(
          MigrationTokensTableCompanion.insert(
            tokenHash: tokenHash,
            newActorUrl: Value(newActorUrl),
            usedAt: Value(DateTime.now().toUtc()),
          ),
        );

    AppLogger.info(
      'Move activity broadcast to ${followers.length} followers',
      tag: 'migration',
    );
    return MoveOk();
  }
}
