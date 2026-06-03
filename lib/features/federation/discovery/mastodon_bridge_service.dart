import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nightingale/core/activitypub/models/ap_collection.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/logging/app_logger.dart';

const _tag = 'mastodon_bridge';
const _collectionCap = 200;
const _rateLimitWindow = Duration(hours: 1);

/// A Nightingale actor discovered via a Mastodon social graph import.
class MastodonMatch {
  const MastodonMatch({
    required this.actorUrl,
    required this.displayName,
    this.avatarUrl,
  });

  final String actorUrl;
  final String displayName;
  final String? avatarUrl;
}

/// Bridges Mastodon social graphs into Nightingale.
///
/// Given a Mastodon handle, this service:
///  1. Resolves the actor via WebFinger
///  2. Fetches followers and following collections (up to 200 each)
///  3. Scans each actor for the `x-nightingale-actor-url` extension field
///  4. Resolves and caches found Nightingale actors
///  5. Returns them as suggested follows
///
/// Rate-limited to one import per Mastodon instance per hour.
/// All network errors are handled gracefully — partial results are valid.
class MastodonBridgeService {
  MastodonBridgeService({
    required ActorResolver actorResolver,
    http.Client? client,
  })  : _actorResolver = actorResolver,
        _client = client ?? http.Client();

  final ActorResolver _actorResolver;
  final http.Client _client;
  final Map<String, DateTime> _lastImportByInstance = {};

  // ── Handle parsing ─────────────────────────────────────────────────────────

  /// Validates a Mastodon handle and returns the instance domain.
  /// Accepts `@user@instance` or `user@instance` format.
  /// Returns null if the handle is malformed.
  static String? parseInstance(String handle) {
    final stripped = handle.startsWith('@') ? handle.substring(1) : handle;
    final parts = stripped.split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) return null;
    return parts[1];
  }

  /// Returns a validation error string if the handle is malformed, else null.
  static String? validateHandle(String handle) {
    if (parseInstance(handle) == null) {
      return 'Enter a handle like @you@mastodon.social';
    }
    return null;
  }

  // ── Rate limiting ──────────────────────────────────────────────────────────

  /// Returns true if this instance is rate-limited (imported within the last hour).
  bool isRateLimited(String instance) {
    final last = _lastImportByInstance[instance];
    if (last == null) return false;
    return DateTime.now().difference(last) < _rateLimitWindow;
  }

  void _markImport(String instance) {
    _lastImportByInstance[instance] = DateTime.now();
  }

  // ── Main import flow ───────────────────────────────────────────────────────

  /// Imports the social graph for [instance] using an OAuth [accessToken].
  ///
  /// Uses the Mastodon API directly with bearer auth, which gives access to
  /// private accounts and removes the unauthenticated collection cap.
  /// Never throws — returns an empty list on any failure.
  Future<List<MastodonMatch>> importSocialGraphAuthenticated(
    String instance,
    String accessToken,
  ) async {
    AppLogger.debug(
      'Starting authenticated Mastodon import for $instance',
      tag: _tag,
    );

    try {
      // Fetch the authenticated user's account to get their collection URLs.
      final accountResponse = await _client.get(
        Uri.https(instance, '/api/v1/accounts/verify_credentials'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (accountResponse.statusCode != 200) {
        AppLogger.debug(
          'verify_credentials failed: ${accountResponse.statusCode}',
          tag: _tag,
        );
        return [];
      }

      final accountJson =
          jsonDecode(accountResponse.body) as Map<String, dynamic>;
      final accountId = accountJson['id'] as String?;
      if (accountId == null) return [];

      // Fetch followers and following via authenticated API endpoints.
      final actorJsonByUrl = <String, Map<String, dynamic>>{};
      for (final endpoint in [
        '/api/v1/accounts/$accountId/followers',
        '/api/v1/accounts/$accountId/following',
      ]) {
        final items = await _fetchApiCollection(
          instance,
          endpoint,
          accessToken,
        );
        for (final entry in items.entries) {
          actorJsonByUrl.putIfAbsent(entry.key, () => entry.value);
        }
      }

      return _matchNightingaleActors(actorJsonByUrl);
    } catch (e) {
      AppLogger.debug('Authenticated import error: $e', tag: _tag);
      return [];
    }
  }

  /// Fetches a Mastodon REST API collection (followers/following) with auth,
  /// following Link header pagination. Returns raw account JSON keyed by URL.
  Future<Map<String, Map<String, dynamic>>> _fetchApiCollection(
    String instance,
    String endpoint,
    String accessToken,
  ) async {
    final result = <String, Map<String, dynamic>>{};
    String? nextUrl = Uri.https(instance, endpoint, {'limit': '80'}).toString();

    while (nextUrl != null) {
      try {
        final response = await _client.get(
          Uri.parse(nextUrl),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) break;

        final list = jsonDecode(response.body) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final url = item['url'] as String? ?? item['id'] as String?;
            if (url != null) result.putIfAbsent(url, () => item);
          }
        }

        // Follow Link: <next_url>; rel="next" pagination.
        final linkHeader = response.headers['link'] ?? '';
        nextUrl = _extractNextLink(linkHeader);
      } catch (_) {
        break;
      }
    }
    return result;
  }

  static String? _extractNextLink(String linkHeader) {
    for (final part in linkHeader.split(',')) {
      if (part.contains('rel="next"')) {
        final match = RegExp(r'<([^>]+)>').firstMatch(part);
        return match?.group(1);
      }
    }
    return null;
  }

  /// Shared logic: scan actor JSON map for x-nightingale-actor-url and
  /// resolve matched Nightingale actors.
  Future<List<MastodonMatch>> _matchNightingaleActors(
    Map<String, Map<String, dynamic>> actorJsonByUrl,
  ) async {
    final matches = <MastodonMatch>[];
    final seen = <String>{};

    for (final actorJson in actorJsonByUrl.values) {
      final nightingaleUrl = _extractNightingaleUrl(actorJson);
      if (nightingaleUrl == null) continue;
      if (!seen.add(nightingaleUrl)) continue;

      final nightingaleResult = await _actorResolver.resolve(
        nightingaleUrl,
        discoverySource: 'mastodonImport',
      );

      if (nightingaleResult is ResolveOk) {
        final actor = nightingaleResult.actor;
        matches.add(MastodonMatch(
          actorUrl: actor.id,
          displayName: actor.name.isNotEmpty ? actor.name : actor.preferredUsername,
          avatarUrl: actor.icon,
        ));
      }
    }

    AppLogger.debug(
      'Authenticated import complete: ${matches.length} matches',
      tag: _tag,
    );
    return matches;
  }

  /// Imports the Mastodon social graph for [handle] and returns matching
  /// Nightingale actors as suggested follows.
  ///
  /// Never throws — returns an empty list on any failure.
  Future<List<MastodonMatch>> importSocialGraph(String handle) async {
    final instance = parseInstance(handle);
    if (instance == null) return [];

    if (isRateLimited(instance)) {
      AppLogger.debug(
        'Mastodon import rate-limited for $instance',
        tag: _tag,
      );
      return [];
    }

    AppLogger.debug('Starting Mastodon import for $handle', tag: _tag);

    // 1. Resolve the user's Mastodon actor.
    final actorResult = await _actorResolver.resolve(handle);
    if (actorResult is! ResolveOk) {
      AppLogger.debug(
        'Failed to resolve Mastodon actor for $handle',
        tag: _tag,
      );
      return [];
    }
    final mastodonActor = actorResult.actor;

    // 2. Fetch followers and following collections, merge, deduplicate.
    final collectionUrls = [mastodonActor.followers, mastodonActor.following];
    final actorJsonByUrl = <String, Map<String, dynamic>>{};

    for (final collectionUrl in collectionUrls) {
      final items = await _fetchCollectionActorJsons(collectionUrl);
      for (final entry in items.entries) {
        actorJsonByUrl.putIfAbsent(entry.key, () => entry.value);
      }
    }

    _markImport(instance);

    return _matchNightingaleActors(actorJsonByUrl);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  /// Fetches a collection and returns raw actor JSON objects keyed by actor URL.
  /// Handles 401/403 gracefully (returns empty map). Capped at [_collectionCap].
  Future<Map<String, Map<String, dynamic>>> _fetchCollectionActorJsons(
    String collectionUrl,
  ) async {
    final result = <String, Map<String, dynamic>>{};
    try {
      final response = await _client.get(
        Uri.parse(collectionUrl),
        headers: {'Accept': 'application/activity+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 401 || response.statusCode == 403) return {};
      if (response.statusCode != 200) return {};

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final collection = ApOrderedCollection.fromJson(json);

      // Inline items.
      if (collection.orderedItems != null) {
        for (final item in collection.orderedItems!) {
          if (result.length >= _collectionCap) break;
          _extractActorJson(item, result);
        }
      }

      // First page of paginated collection.
      if (result.length < _collectionCap && collection.first != null) {
        final pageResp = await _client.get(
          Uri.parse(collection.first!),
          headers: {'Accept': 'application/activity+json'},
        ).timeout(const Duration(seconds: 10));

        if (pageResp.statusCode == 200) {
          final pageJson = jsonDecode(pageResp.body) as Map<String, dynamic>;
          final page = ApOrderedCollectionPage.fromJson(pageJson);
          for (final item in page.orderedItems) {
            if (result.length >= _collectionCap) break;
            _extractActorJson(item, result);
          }
        }
      }
    } catch (e) {
      AppLogger.debug(
        'Mastodon collection fetch failed ($collectionUrl): $e',
        tag: _tag,
      );
    }
    return result;
  }

  void _extractActorJson(
    dynamic item,
    Map<String, Map<String, dynamic>> out,
  ) {
    if (item is Map<String, dynamic>) {
      final id = item['id'] as String?;
      if (id != null) out[id] = item;
    }
    // String URLs only — we need the full JSON to check for the extension field,
    // so plain URL entries are skipped (Mastodon returns full objects in
    // followers/following collections).
  }

  /// Extracts the `x-nightingale-actor-url` extension field from a raw actor
  /// JSON object. Returns null if absent or malformed.
  static String? _extractNightingaleUrl(Map<String, dynamic> actorJson) {
    final raw = actorJson['x-nightingale-actor-url'];
    if (raw is! String || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.scheme != 'https') return null;
    return raw;
  }
}
