import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/discovery/mastodon_oauth_service.dart';

const _tag = 'mastodon_profile_sync';

/// Publishes the device's Nightingale actor URL and STUN-discovered public
/// address to the user's Mastodon profile as custom fields, making the device
/// discoverable by other Nightingale users via the Mastodon bridge.
///
/// Fields written:
///   x-nightingale-actor-url      — stable ActivityPub identity URL
///   x-nightingale-public-address — current public IP:port from STUN
class MastodonProfileSyncService {
  MastodonProfileSyncService({
    required MastodonOAuthService oauthService,
    http.Client? client,
  })  : _oauth = oauthService,
        _client = client ?? http.Client();

  final MastodonOAuthService _oauth;
  final http.Client _client;

  String? _lastPublishedAddress;
  bool _needsReauth = false;

  /// True when the stored token lacks `write:accounts` — UI should prompt re-auth.
  bool get needsReauth => _needsReauth;

  /// Writes [actorUrl] and [publicAddress] to the user's Mastodon profile.
  ///
  /// No-ops silently when:
  /// - No Mastodon account is connected
  /// - [publicAddress] matches the last successfully published value
  ///
  /// Fire-and-forget safe: all errors are caught and logged.
  Future<void> sync({
    required String actorUrl,
    required String publicAddress,
  }) async {
    print('NIGHTINGALE SYNC: sync() called actorUrl=$actorUrl publicAddress=$publicAddress lastPublished=$_lastPublishedAddress');
    if (publicAddress == _lastPublishedAddress) {
      print('NIGHTINGALE SYNC: address unchanged — skipping');
      return;
    }

    final creds = await _oauth.getStoredCredentials();
    if (creds == null) {
      print('NIGHTINGALE SYNC: no Mastodon account connected — skipping');
      return;
    }
    print('NIGHTINGALE SYNC: using account on ${creds.instance}');

    try {
      // Fetch current profile to read existing custom fields.
      final profileRes = await _client.get(
        Uri.https(creds.instance, '/api/v1/accounts/verify_credentials'),
        headers: {
          'Authorization': 'Bearer ${creds.token}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (profileRes.statusCode == 403) {
        AppLogger.warning(
          'MastodonProfileSync: token lacks write:accounts — re-auth needed',
          tag: _tag,
        );
        _needsReauth = true;
        return;
      }
      if (profileRes.statusCode != 200) {
        AppLogger.warning(
          'MastodonProfileSync: verify_credentials returned ${profileRes.statusCode}',
          tag: _tag,
        );
        return;
      }

      final profileJson = jsonDecode(profileRes.body) as Map<String, dynamic>;
      final existingFields = (profileJson['fields'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      final mergedFields = _mergeNightingaleFields(
        existing: existingFields,
        actorUrl: actorUrl,
        publicAddress: publicAddress,
      );

      // Build PATCH body using indexed field_attributes form encoding.
      final body = <String, String>{};
      for (var i = 0; i < mergedFields.length; i++) {
        body['fields_attributes[$i][name]'] = mergedFields[i]['name']!;
        body['fields_attributes[$i][value]'] = mergedFields[i]['value']!;
      }

      final patchRes = await _client.patch(
        Uri.https(creds.instance, '/api/v1/accounts/update_credentials'),
        headers: {'Authorization': 'Bearer ${creds.token}'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (patchRes.statusCode == 403) {
        AppLogger.warning(
          'MastodonProfileSync: update_credentials 403 — re-auth needed',
          tag: _tag,
        );
        _needsReauth = true;
        return;
      }

      if (patchRes.statusCode == 200) {
        _lastPublishedAddress = publicAddress;
        _needsReauth = false;
        print('NIGHTINGALE SYNC: SUCCESS — published actorUrl=$actorUrl publicAddress=$publicAddress');
      } else {
        print('NIGHTINGALE SYNC: FAILED — update_credentials returned ${patchRes.statusCode} body=${patchRes.body}');
      }
    } catch (e, st) {
      print('NIGHTINGALE SYNC: ERROR — $e');
      print('NIGHTINGALE SYNC: STACK — $st');
    }
  }

  /// Removes both Nightingale fields from the user's Mastodon profile.
  ///
  /// No-ops silently when no Mastodon account is connected. Resets
  /// [_lastPublishedAddress] so a subsequent [sync] call always re-publishes.
  Future<void> clearAddress() async {
    final creds = await _oauth.getStoredCredentials();
    if (creds == null) return;

    try {
      final profileRes = await _client.get(
        Uri.https(creds.instance, '/api/v1/accounts/verify_credentials'),
        headers: {
          'Authorization': 'Bearer ${creds.token}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (profileRes.statusCode != 200) {
        AppLogger.warning(
          'MastodonProfileSync: clearAddress verify_credentials returned ${profileRes.statusCode}',
          tag: _tag,
        );
        return;
      }

      const nightingaleNames = {
        'x-nightingale-actor-url',
        'x-nightingale-public-address',
      };

      final profileJson =
          jsonDecode(profileRes.body) as Map<String, dynamic>;
      final existingFields =
          (profileJson['fields'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .toList();

      final remaining = existingFields
          .where((f) => !nightingaleNames
              .contains((f['name'] as String? ?? '').toLowerCase()))
          .toList();

      final body = <String, String>{};
      for (var i = 0; i < remaining.length; i++) {
        body['fields_attributes[$i][name]'] =
            remaining[i]['name'] as String? ?? '';
        body['fields_attributes[$i][value]'] =
            remaining[i]['value'] as String? ?? '';
      }

      final patchRes = await _client.patch(
        Uri.https(creds.instance, '/api/v1/accounts/update_credentials'),
        headers: {'Authorization': 'Bearer ${creds.token}'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (patchRes.statusCode == 200) {
        _lastPublishedAddress = null;
        AppLogger.info('MastodonProfileSync: cleared address fields', tag: _tag);
      } else {
        AppLogger.warning(
          'MastodonProfileSync: clearAddress update_credentials returned ${patchRes.statusCode}',
          tag: _tag,
        );
      }
    } catch (e) {
      AppLogger.warning('MastodonProfileSync: clearAddress failed: $e',
          tag: _tag);
    }
  }

  // Replaces existing Nightingale fields in-place and appends new ones,
  // keeping total ≤ 4 (Mastodon's limit) by dropping excess non-Nightingale fields.
  static List<Map<String, String>> _mergeNightingaleFields({
    required List<Map<String, dynamic>> existing,
    required String actorUrl,
    required String publicAddress,
  }) {
    const nightingaleNames = {
      'x-nightingale-actor-url',
      'x-nightingale-public-address',
    };

    final nonNightingale = existing
        .where((f) => !nightingaleNames.contains(
            (f['name'] as String? ?? '').toLowerCase()))
        .map((f) => {
              'name': f['name'] as String? ?? '',
              'value': f['value'] as String? ?? '',
            })
        .toList();

    // Mastodon allows 4 fields max; reserve 2 slots for Nightingale fields.
    final kept = nonNightingale.take(2).toList();
    return [
      ...kept,
      {'name': 'x-nightingale-actor-url', 'value': actorUrl},
      {'name': 'x-nightingale-public-address', 'value': publicAddress},
    ];
  }
}
