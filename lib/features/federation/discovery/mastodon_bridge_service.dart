import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
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

/// Result of a single Mastodon handle lookup.
sealed class HandleLookupResult {}

/// Handle was not found on Mastodon (WebFinger failed or account doesn't exist).
class HandleLookupNotFound extends HandleLookupResult {}

/// Account exists on Mastodon but has not published a Nightingale actor URL.
class HandleLookupNotNightingale extends HandleLookupResult {}

/// Account found and is a Nightingale peer.
class HandleLookupFound extends HandleLookupResult {
  HandleLookupFound(this.match, this.mastodonHandle);
  final MastodonMatch match;
  final String mastodonHandle;
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
  /// resolve matched Nightingale actors, synthesizing from Mastodon data
  /// when the device is behind NAT and unreachable directly.
  Future<List<MastodonMatch>> _matchNightingaleActors(
    Map<String, Map<String, dynamic>> actorJsonByUrl,
  ) async {
    final matches = <MastodonMatch>[];
    final seen = <String>{};

    for (final actorJson in actorJsonByUrl.values) {
      final nightingaleUrl = _extractNightingaleUrl(actorJson);
      if (nightingaleUrl == null) continue;
      if (!seen.add(nightingaleUrl)) continue;

      final mastodonDisplayName =
          (actorJson['name'] as String?)?.trim() ??
          (actorJson['preferredUsername'] as String?) ??
          '';
      final iconRaw = actorJson['icon'];
      final mastodonAvatarUrl = iconRaw is Map
          ? iconRaw['url'] as String?
          : iconRaw as String?;
      final nightingalePublicAddress =
          _extractFieldValue(actorJson, 'x-nightingale-public-address');

      ApActor actor;
      final result = await _actorResolver.resolve(
        nightingaleUrl,
        discoverySource: 'mastodonImport',
      );
      if (result is ResolveOk) {
        actor = result.actor;
      } else {
        actor = await _actorResolver.synthesizeAndCache(
          nightingaleUrl,
          displayName: mastodonDisplayName,
          nightingalePublicAddress: nightingalePublicAddress,
          avatarUrl: mastodonAvatarUrl,
          discoverySource: 'mastodonImport',
        );
      }

      matches.add(MastodonMatch(
        actorUrl: actor.id,
        displayName: actor.name.isNotEmpty ? actor.name : actor.preferredUsername,
        avatarUrl: actor.icon,
      ));
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

  // ── Single-handle lookup ───────────────────────────────────────────────────

  /// Looks up a single Mastodon handle and returns a [HandleLookupResult].
  ///
  /// Flow:
  ///   1. WebFinger the handle to get the Mastodon actor URL
  ///   2. Fetch the Mastodon actor JSON (ActivityPub format)
  ///   3. Extract `x-nightingale-actor-url` from the actor's fields
  ///   4. Resolve the Nightingale actor via [ActorResolver]
  ///
  /// Never throws — all errors surface as [HandleLookupNotFound].
  Future<HandleLookupResult> lookupByHandle(String handle) async {
    final stripped = handle.startsWith('@') ? handle.substring(1) : handle;
    final parts = stripped.split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      return HandleLookupNotFound();
    }
    final domain = parts[1];

    try {
      // 1. WebFinger → Mastodon actor URL.
      String? mastodonActorUrl;
      for (final scheme in ['https', 'http']) {
        try {
          final uri = Uri.parse(
            '$scheme://$domain/.well-known/webfinger?resource=acct:$stripped',
          );
          final res = await _client
              .get(uri, headers: {'Accept': 'application/jrd+json'})
              .timeout(const Duration(seconds: 8));
          if (res.statusCode == 200) {
            final jrd = jsonDecode(res.body) as Map<String, dynamic>;
            final links = (jrd['links'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .where((l) => l['rel'] == 'self')
                .toList();
            mastodonActorUrl = links
                ?.map((l) => l['href'] as String?)
                .firstWhere((h) => h != null, orElse: () => null);
            if (mastodonActorUrl != null) break;
          }
        } catch (_) {
          continue;
        }
      }

      if (mastodonActorUrl == null) {
        AppLogger.debug('lookupByHandle: WebFinger failed for $handle', tag: _tag);
        return HandleLookupNotFound();
      }

      // 2. Fetch Mastodon actor JSON.
      final actorRes = await _client
          .get(
            Uri.parse(mastodonActorUrl),
            headers: {'Accept': 'application/activity+json'},
          )
          .timeout(const Duration(seconds: 8));

      if (actorRes.statusCode != 200) {
        AppLogger.debug(
          'lookupByHandle: actor fetch ${actorRes.statusCode} for $mastodonActorUrl',
          tag: _tag,
        );
        return HandleLookupNotFound();
      }

      final actorJson = jsonDecode(actorRes.body) as Map<String, dynamic>;

      // 3. Extract x-nightingale-actor-url.
      final nightingaleUrl = _extractNightingaleUrl(actorJson);
      if (nightingaleUrl == null) {
        AppLogger.debug(
          'lookupByHandle: $handle is on Mastodon but not Nightingale',
          tag: _tag,
        );
        return HandleLookupNotNightingale();
      }

      // Extract supporting data available from the Mastodon actor for synthesis.
      final mastodonDisplayName =
          (actorJson['name'] as String?)?.trim() ?? stripped.split('@').first;
      final iconRaw = actorJson['icon'];
      final mastodonAvatarUrl = iconRaw is Map
          ? iconRaw['url'] as String?
          : iconRaw as String?;
      final nightingalePublicAddress =
          _extractFieldValue(actorJson, 'x-nightingale-public-address');

      // 4. Resolve Nightingale actor — synthesize from Mastodon data on failure
      //    (device may be behind NAT and unreachable directly).
      ApActor actor;
      final result = await _actorResolver.resolve(
        nightingaleUrl,
        discoverySource: 'mastodonHandleLookup',
      );
      if (result is ResolveOk) {
        actor = result.actor;
      } else {
        AppLogger.debug(
          'lookupByHandle: direct resolve failed for $nightingaleUrl — synthesizing from Mastodon data',
          tag: _tag,
        );
        actor = await _actorResolver.synthesizeAndCache(
          nightingaleUrl,
          displayName: mastodonDisplayName,
          nightingalePublicAddress: nightingalePublicAddress,
          avatarUrl: mastodonAvatarUrl,
          discoverySource: 'mastodonHandleLookup',
        );
      }

      final match = MastodonMatch(
        actorUrl: actor.id,
        displayName: actor.name.isNotEmpty ? actor.name : actor.preferredUsername,
        avatarUrl: actor.icon,
      );

      AppLogger.info(
        'lookupByHandle: found Nightingale peer $handle → ${actor.id}',
        tag: _tag,
      );
      return HandleLookupFound(match, '@$stripped');
    } catch (e) {
      AppLogger.debug('lookupByHandle error for $handle: $e', tag: _tag);
      return HandleLookupNotFound();
    }
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

  /// Extracts a named field value from a Mastodon actor JSON object.
  /// Handles both REST API `fields` array and ActivityPub `attachment` array.
  static String? _extractFieldValue(Map<String, dynamic> actorJson, String fieldName) {
    final lower = fieldName.toLowerCase();

    final fields = actorJson['fields'];
    if (fields is List) {
      for (final f in fields) {
        if (f is Map<String, dynamic>) {
          if ((f['name'] as String? ?? '').toLowerCase().trim() == lower) {
            return f['value'] as String?;
          }
        }
      }
    }

    final attachment = actorJson['attachment'];
    if (attachment is List) {
      for (final item in attachment) {
        if (item is Map<String, dynamic>) {
          if ((item['name'] as String? ?? '').toLowerCase().trim() == lower) {
            return item['value'] as String?;
          }
        }
      }
    }

    return actorJson[fieldName] as String?;
  }

  /// Extracts the `x-nightingale-actor-url` extension field from a raw actor
  /// JSON object. Returns null if absent or malformed.
  static String? _extractNightingaleUrl(Map<String, dynamic> actorJson) {
    // Mastodon REST API format (authenticated import):
    // { "fields": [{"name": "x-nightingale-actor-url", "value": "http://..."}] }
    final fields = actorJson['fields'];
    if (fields is List) {
      for (final field in fields) {
        if (field is Map<String, dynamic>) {
          final name = (field['name'] as String? ?? '').toLowerCase().trim();
          if (name == 'x-nightingale-actor-url') {
            final value = field['value'] as String?;
            if (value != null && value.isNotEmpty) {
              return _validateUrl(value);
            }
          }
        }
      }
    }

    // ActivityPub actor format (unauthenticated / WebFinger path):
    // { "attachment": [{"type": "PropertyValue", "name": "...", "value": "..."}] }
    final attachment = actorJson['attachment'];
    if (attachment is List) {
      for (final item in attachment) {
        if (item is Map<String, dynamic>) {
          final name = (item['name'] as String? ?? '').toLowerCase().trim();
          if (name == 'x-nightingale-actor-url') {
            final value = item['value'] as String?;
            if (value != null && value.isNotEmpty) {
              return _validateUrl(value);
            }
          }
        }
      }
    }

    // Legacy: top-level key kept for backwards compatibility.
    final raw = actorJson['x-nightingale-actor-url'];
    if (raw is String && raw.isNotEmpty) return _validateUrl(raw);

    return null;
  }

  static String? _validateUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) return null;
    // Accept both http and https — Nightingale nodes use plain HTTP.
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return raw;
  }
}
