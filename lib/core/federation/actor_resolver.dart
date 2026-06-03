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

// Priority order for discovery source tagging.
// Higher number = higher priority; a higher-priority source is never overwritten.
const _sourcePriority = {
  'manual': 5,
  'mDNS': 4,
  'mastodonImport': 3,
  'stun': 2,
  'peerExchange': 1,
};

class ActorResolver {
  ActorResolver({required this.db, this.ttlSeconds = 900, http.Client? client})
      : _client = client ?? http.Client();

  final AppDatabase db;
  final int ttlSeconds;
  final http.Client _client;

  Future<ResolveResult> resolve(
    String handleOrUrl, {
    String discoverySource = 'manual',
  }) async {
    final isHandle = handleOrUrl.contains('@') &&
        !handleOrUrl.startsWith('http://') &&
        !handleOrUrl.startsWith('https://');
    final actorUrl = isHandle
        ? await _webFingerToUrl(handleOrUrl)
        : handleOrUrl;

    if (actorUrl == null) {
      return ResolveFailed('WebFinger lookup failed for $handleOrUrl');
    }

    // Cache check
    final cached = await _readCache(actorUrl);
    if (cached != null) return ResolveOk(cached);

    // Network fetch
    return _fetchAndCache(actorUrl, discoverySource: discoverySource);
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

  Future<ResolveResult> _fetchAndCache(
    String actorUrl, {
    String discoverySource = 'manual',
  }) async {
    try {
      final response = await _client.get(
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

      // Preserve a higher-priority discoverySource already on this record.
      final existing = await (db.select(db.actorCacheTable)
            ..where((t) => t.actorUrl.equals(actorUrl)))
          .getSingleOrNull();
      final effectiveSource = _mergeSource(existing?.discoverySource, discoverySource);

      await db.into(db.actorCacheTable).insertOnConflictUpdate(
            ActorCacheTableCompanion.insert(
              actorUrl: actorUrl,
              actorJson: response.body,
              ttlSeconds: Value(ttlSeconds),
              discoverySource: Value(effectiveSource),
            ),
          );

      AppLogger.debug('Actor cached: $actorUrl [$effectiveSource]',
          tag: 'actor_cache');
      return ResolveOk(actor);
    } catch (e) {
      return ResolveFailed('Actor fetch/parse error for $actorUrl: $e');
    }
  }

  // Returns whichever source has higher priority, keeping the existing one
  // when priorities are equal (stable — don't thrash on re-fetch).
  static String _mergeSource(String? existing, String incoming) {
    if (existing == null) return incoming;
    final existingPriority = _sourcePriority[existing] ?? 0;
    final incomingPriority = _sourcePriority[incoming] ?? 0;
    return incomingPriority > existingPriority ? incoming : existing;
  }

  Future<String?> _webFingerToUrl(String handle) async {
    // handle: @user@domain or user@domain
    final stripped = handle.startsWith('@') ? handle.substring(1) : handle;
    final parts = stripped.split('@');
    if (parts.length != 2) return null;
    final domain = parts[1];
    final queryParams = {'resource': 'acct:$stripped'};
    const headers = {'Accept': 'application/jrd+json'};

    // Try HTTPS first; fall back to HTTP for Nightingale nodes on plain HTTP.
    for (final scheme in ['https', 'http']) {
      try {
        final uri = scheme == 'https'
            ? Uri.https(domain, '/.well-known/webfinger', queryParams)
            : Uri.http(domain, '/.well-known/webfinger', queryParams);
        final response = await _client.get(uri, headers: headers)
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final jrd = WebFingerJrd.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
          return jrd.selfHref;
        }
      } catch (_) {
        // Try next scheme.
      }
    }
    return null;
  }
}
