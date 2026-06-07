import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/discovery/mastodon_oauth_service.dart';
import 'package:nightingale/features/federation/nat/peer_address_activity.dart';

const _tag = 'mastodon_signaling';
const _signalMarker = 'nightingale-signal:';
final _signalRegex = RegExp(r'nightingale-signal:([A-Za-z0-9+/=_-]+)');

/// Routes hole-punch PeerAddress signals through Mastodon DMs when the direct
/// Nightingale inbox is unreachable (CGNAT scenario).
///
/// Sending: posts a `visibility: direct` status mentioning the target handle.
/// Receiving: polls `GET /api/v1/notifications?types[]=mention` for incoming
/// signal DMs and dispatches them to a registered handler.
class MastodonSignalingService {
  MastodonSignalingService({
    required MastodonOAuthService oauthService,
    http.Client? client,
  })  : _oauth = oauthService,
        _client = client ?? http.Client();

  final MastodonOAuthService _oauth;
  final http.Client _client;

  // Notification IDs already dispatched this session — prevents double-dispatch
  // before a dismiss completes.
  final _processedIds = <String>{};

  Timer? _backgroundTimer;
  bool _pollBusy = false;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Sends [signal] as a Mastodon DM to [targetMastodonHandle].
  ///
  /// Returns silently on any error or missing credentials — callers should not
  /// depend on delivery confirmation.
  Future<void> sendSignal({
    required String targetMastodonHandle,
    required PeerAddressActivity signal,
  }) async {
    final creds = await _oauth.getStoredCredentials();
    if (creds == null) {
      AppLogger.debug(
        'MastodonSignaling: no credentials — skipping DM send',
        tag: _tag,
      );
      return;
    }

    final handle = targetMastodonHandle.startsWith('@')
        ? targetMastodonHandle
        : '@$targetMastodonHandle';

    final minimal = {
      'n': signal.sessionNonce,
      'f': signal.fromActorUrl,
      'p': signal.publicAddress,
      if (signal.senderMastodonHandle != null) 's': signal.senderMastodonHandle,
    };
    final payload = base64Url.encode(utf8.encode(jsonEncode(minimal)));
    final body = '$handle $_signalMarker$payload';

    print('DEBUG_SIGNAL: sending DM to $handle nonce=${signal.sessionNonce}');
    try {
      final response = await _client.post(
        Uri.https(creds.instance, '/api/v1/statuses'),
        headers: {
          'Authorization': 'Bearer ${creds.token}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'status': body, 'visibility': 'direct'},
      ).timeout(const Duration(seconds: 8));

      print('DEBUG_SIGNAL: DM send status=${response.statusCode} for $handle');
    } catch (e) {
      print('DEBUG_SIGNAL: DM send error for $handle: $e');
    }
  }

  /// Polls `GET /api/v1/notifications?types[]=mention` once.
  ///
  /// Finds mentions containing a `nightingale-signal:` payload, parses them
  /// as [PeerAddressActivity], dismisses processed notifications, and returns
  /// the list of valid signals.
  Future<List<PeerAddressActivity>> pollOnce() async {
    final creds = await _oauth.getStoredCredentials();
    if (creds == null) return [];

    try {
      final response = await _client.get(
        Uri.https(creds.instance, '/api/v1/notifications', {
          'types[]': 'mention',
          'limit': '40',
        }),
        headers: {
          'Authorization': 'Bearer ${creds.token}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        print('DEBUG_SIGNAL: poll failed status=${response.statusCode} body=${response.body.substring(0, response.body.length.clamp(0, 200))}');
        return [];
      }

      final notifications =
          (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
      print('DEBUG_SIGNAL: poll status=${response.statusCode} got ${notifications.length} notifications');
      final results = <PeerAddressActivity>[];

      for (final n in notifications) {
        final id = n['id'] as String?;
        if (id == null) continue;
        if (_processedIds.contains(id)) continue;

        final status = n['status'] as Map<String, dynamic>?;
        if (status == null) continue;

        final content = status['content'] as String? ?? '';
        final match = _signalRegex.firstMatch(content);
        if (match == null) continue;

        final encoded = match.group(1)!;
        try {
          final decoded = utf8.decode(base64Url.decode(encoded));
          final json = jsonDecode(decoded) as Map<String, dynamic>;
          final signal = PeerAddressActivity.fromSignalJson(json);
          if (signal == null) continue;

          _processedIds.add(id);
          results.add(signal);

          AppLogger.info(
            'MastodonSignaling: received PeerAddress signal '
            'nonce=${signal.sessionNonce} from notification $id',
            tag: _tag,
          );

          // Dismiss so it doesn't re-appear on future polls.
          _dismissNotification(creds, id).ignore();
        } catch (e) {
          AppLogger.debug(
            'MastodonSignaling: failed to parse signal from notification $id: $e',
            tag: _tag,
          );
        }
      }

      return results;
    } catch (e) {
      AppLogger.debug('MastodonSignaling: poll error: $e', tag: _tag);
      return [];
    }
  }

  /// Starts a 2-second background poll for passive reception of incoming
  /// PeerAddress signals (Device B as responder).
  ///
  /// [onSignal] is called for each valid signal found. Only one concurrent
  /// poll runs at a time — overlapping calls are skipped.
  void startBackgroundPolling(void Function(PeerAddressActivity) onSignal) {
    _backgroundTimer?.cancel();
    _pollBusy = false;

    AppLogger.debug('MastodonSignaling: starting background polling', tag: _tag);

    _backgroundTimer =
        Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_pollBusy) return;
      _pollBusy = true;
      try {
        final signals = await pollOnce();
        for (final signal in signals) {
          onSignal(signal);
        }
      } finally {
        _pollBusy = false;
      }
    });
  }

  /// Stops the background polling timer.
  void stopBackgroundPolling() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    _pollBusy = false;
    AppLogger.debug('MastodonSignaling: stopped background polling', tag: _tag);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _dismissNotification(
    ({String instance, String token}) creds,
    String notificationId,
  ) async {
    try {
      await _client.post(
        Uri.https(
          creds.instance,
          '/api/v1/notifications/$notificationId/dismiss',
        ),
        headers: {'Authorization': 'Bearer ${creds.token}'},
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      AppLogger.debug('MastodonSignaling: dismiss $notificationId failed: $e', tag: _tag);
    }
  }
}
