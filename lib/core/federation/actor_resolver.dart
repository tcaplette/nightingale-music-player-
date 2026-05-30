import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/activitypub/models/webfinger_jrd.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/logging/app_logger.dart';

sealed class ResolveResult {}

class ResolveOk extends ResolveResult {
  ResolveOk(this.actor);
  final ApActor actor;
}

class ResolveFailed extends ResolveResult {
  ResolveFailed(this.reason);
  final String reason;
}

class ActorResolver {
  ActorResolver({required this.db, this.ttlSeconds = 900});

  final AppDatabase db;
  final int ttlSeconds;

  Future<ResolveResult> resolve(String handleOrUrl) async {
    final actorUrl = handleOrUrl.startsWith('@')
        ? await _webFingerToUrl(handleOrUrl)
        : handleOrUrl;

    if (actorUrl == null) {
      return ResolveFailed('WebFinger lookup failed for $handleOrUrl');
    }

    // Cache check
    final cached = await _readCache(actorUrl);
    if (cached != null) return ResolveOk(cached);

    // Network fetch
    return _fetchAndCache(actorUrl);
  }

  Future<void> invalidate(String actorUrl) async {
    await (db.delete(db.actorCacheTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .go();
    AppLogger.debug('Actor cache invalidated: $actorUrl', tag: 'actor_cache');
  }

  // Returns all cached entries for the debug inspector.
  Future<List<ActorCacheTableData>> getCacheEntries() =>
      db.select(db.actorCacheTable).get();

  // ── Private ───────────────────────────────────────────────────────────────

  Future<ApActor?> _readCache(String actorUrl) async {
    final row = await (db.select(db.actorCacheTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .getSingleOrNull();
    if (row == null) return null;

    final age = DateTime.now().toUtc().difference(row.cachedAt).inSeconds;
    if (age > row.ttlSeconds) {
      await invalidate(actorUrl);
      return null;
    }

    try {
      return ApActor.fromJson(
        jsonDecode(row.actorJson) as Map<String, dynamic>,
      );
    } catch (_) {
      await invalidate(actorUrl);
      return null;
    }
  }

  Future<ResolveResult> _fetchAndCache(String actorUrl) async {
    try {
      final response = await http.get(
        Uri.parse(actorUrl),
        headers: {'Accept': 'application/activity+json'},
      );
      if (response.statusCode != 200) {
        return ResolveFailed(
          'Actor fetch returned ${response.statusCode} for $actorUrl',
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final actor = ApActor.fromJson(json);

      await db.into(db.actorCacheTable).insertOnConflictUpdate(
            ActorCacheTableCompanion.insert(
              actorUrl: actorUrl,
              actorJson: response.body,
              ttlSeconds: Value(ttlSeconds),
            ),
          );

      AppLogger.debug('Actor cached: $actorUrl', tag: 'actor_cache');
      return ResolveOk(actor);
    } catch (e) {
      return ResolveFailed('Actor fetch/parse error for $actorUrl: $e');
    }
  }

  Future<String?> _webFingerToUrl(String handle) async {
    // handle: @user@domain or user@domain
    final stripped = handle.startsWith('@') ? handle.substring(1) : handle;
    final parts = stripped.split('@');
    if (parts.length != 2) return null;
    final domain = parts[1];

    try {
      final uri = Uri.https(
        domain,
        '/.well-known/webfinger',
        {'resource': 'acct:$stripped'},
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/jrd+json'},
      );
      if (response.statusCode != 200) return null;
      final jrd = WebFingerJrd.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      return jrd.selfHref;
    } catch (_) {
      return null;
    }
  }
}
