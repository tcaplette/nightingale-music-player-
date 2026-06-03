import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/onboarding/secure_storage_service.dart';

const _tag = 'mastodon_oauth';
const _redirectUri = 'nightingale://oauth/callback';
const _scopes = 'read:follows read:accounts';
const _clientName = 'Nightingale';

sealed class OAuthResult {}

class OAuthSuccess extends OAuthResult {
  OAuthSuccess({required this.instance, required this.accessToken});
  final String instance;
  final String accessToken;
}

class OAuthCancelled extends OAuthResult {}

class OAuthFailed extends OAuthResult {
  OAuthFailed(this.reason);
  final String reason;
}

class MastodonOAuthService {
  MastodonOAuthService({
    required SecureStorageService storage,
    http.Client? client,
  })  : _storage = storage,
        _client = client ?? http.Client();

  final SecureStorageService _storage;
  final http.Client _client;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Signs in with Mastodon.
  ///
  /// If [password] is provided, attempts the password grant first (no browser
  /// redirect, best UX). Falls back to browser-based OAuth automatically if:
  /// - the instance has disabled the password grant
  /// - the user has two-factor auth enabled
  /// - any other credential error occurs
  ///
  /// If [password] is null, goes straight to browser OAuth.
  Future<OAuthResult> signIn(String handleOrInstance, {String? password}) async {
    final normalised = _normaliseInstance(handleOrInstance);
    AppLogger.debug('Sign-in for $normalised', tag: _tag);

    final creds = await _ensureClientCredentials(normalised);
    if (creds == null) {
      return OAuthFailed('Could not connect to $normalised. Check your account and try again.');
    }

    // Option A: password grant — no browser, single in-app flow.
    if (password != null && password.isNotEmpty) {
      final username = _extractUsername(handleOrInstance);
      if (username != null) {
        final result = await _tryPasswordGrant(
          normalised,
          creds,
          username: username,
          password: password,
        );
        if (result is OAuthSuccess) return result;
        AppLogger.debug(
          'Password grant failed, falling back to browser OAuth',
          tag: _tag,
        );
      }
    }

    // Option B: browser OAuth fallback (PKCE).
    return _browserOAuth(normalised, creds);
  }

  Future<void> signOut(String instance) async {
    final normalised = _normaliseInstance(instance);
    await _storage.clearMastodonCredentials(normalised);
    AppLogger.debug('Sign-out for $normalised', tag: _tag);
  }

  Future<String?> getStoredToken(String instance) =>
      _storage.getMastodonAccessToken(_normaliseInstance(instance));

  Future<bool> isSignedIn(String instance) async {
    final token = await getStoredToken(instance);
    return token != null;
  }

  /// Returns @username@instance after a successful sign-in.
  Future<String?> fetchAccountHandle(String instance, String accessToken) async {
    final normalised = _normaliseInstance(instance);
    try {
      final response = await _client.get(
        Uri.https(normalised, '/api/v1/accounts/verify_credentials'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final username = json['username'] as String?;
      if (username == null) return null;
      return '@$username@$normalised';
    } catch (_) {
      return null;
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<OAuthResult> _tryPasswordGrant(
    String instance,
    ({String clientId, String clientSecret}) creds, {
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        Uri.https(instance, '/oauth/token'),
        body: {
          'client_id': creds.clientId,
          'client_secret': creds.clientSecret,
          'grant_type': 'password',
          'username': username,
          'password': password,
          'scope': _scopes,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        AppLogger.debug(
          'Password grant rejected (${response.statusCode}) — will try browser',
          tag: _tag,
        );
        return OAuthFailed('password_grant_rejected');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = json['access_token'] as String?;
      if (accessToken == null) return OAuthFailed('No access_token');

      await _storage.setMastodonAccessToken(instance, accessToken);
      AppLogger.debug('Password grant success for $instance', tag: _tag);
      return OAuthSuccess(instance: instance, accessToken: accessToken);
    } catch (e) {
      AppLogger.debug('Password grant error: $e', tag: _tag);
      return OAuthFailed('password_grant_error');
    }
  }

  Future<OAuthResult> _browserOAuth(
    String instance,
    ({String clientId, String clientSecret}) creds,
  ) async {
    final verifier = _generateCodeVerifier();
    final challenge = _codeChallenge(verifier);

    final authUrl = Uri.https(instance, '/oauth/authorize', {
      'client_id': creds.clientId,
      'redirect_uri': _redirectUri,
      'response_type': 'code',
      'scope': _scopes,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
    });

    String callbackUrl;
    try {
      callbackUrl = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'nightingale',
      );
    } on Exception catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('dismiss') || msg.contains('user_cancelled')) {
        return OAuthCancelled();
      }
      return OAuthFailed('Sign-in was cancelled or failed.');
    }

    final code = Uri.parse(callbackUrl).queryParameters['code'];
    if (code == null) return OAuthFailed('No code in callback');

    try {
      final tokenResponse = await _client.post(
        Uri.https(instance, '/oauth/token'),
        body: {
          'client_id': creds.clientId,
          'client_secret': creds.clientSecret,
          'redirect_uri': _redirectUri,
          'grant_type': 'authorization_code',
          'code': code,
          'code_verifier': verifier,
        },
      ).timeout(const Duration(seconds: 10));

      if (tokenResponse.statusCode != 200) {
        return OAuthFailed('Sign-in failed. Please try again.');
      }

      final json = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final accessToken = json['access_token'] as String?;
      if (accessToken == null) return OAuthFailed('No access_token in response');

      await _storage.setMastodonAccessToken(instance, accessToken);
      AppLogger.debug('Browser OAuth success for $instance', tag: _tag);
      return OAuthSuccess(instance: instance, accessToken: accessToken);
    } catch (e) {
      return OAuthFailed('Sign-in failed. Please try again.');
    }
  }

  /// Accepts @user@instance.social, user@instance.social, bare domain, or https:// URL.
  String _normaliseInstance(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceFirst(RegExp(r'^https?://'), '');
    if (s.contains('@')) {
      s = s.split('@').last;
    }
    s = s.split('/').first.split('?').first;
    return s;
  }

  /// Extracts the username from a handle (@user@instance or user@instance).
  /// Returns null if the input is just a domain.
  String? _extractUsername(String input) {
    final s = input.trim().replaceFirst(RegExp(r'^@'), '');
    final parts = s.split('@');
    if (parts.length < 2) return null;
    return parts[0].isNotEmpty ? parts[0] : null;
  }

  Future<({String clientId, String clientSecret})?> _ensureClientCredentials(
    String instance,
  ) async {
    final existing = await _storage.getMastodonClientCredentials(instance);
    if (existing != null) return existing;

    try {
      final response = await _client.post(
        Uri.https(instance, '/api/v1/apps'),
        body: {
          'client_name': _clientName,
          'redirect_uris': _redirectUri,
          'scopes': _scopes,
          'website': 'https://github.com/nightingale-app/nightingale',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        AppLogger.debug('App registration failed: ${response.statusCode}', tag: _tag);
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final clientId = json['client_id'] as String?;
      final clientSecret = json['client_secret'] as String?;
      if (clientId == null || clientSecret == null) return null;

      await _storage.setMastodonClientCredentials(instance, clientId, clientSecret);
      AppLogger.debug('App registered on $instance', tag: _tag);
      return (clientId: clientId, clientSecret: clientSecret);
    } catch (e) {
      AppLogger.debug('App registration error: $e', tag: _tag);
      return null;
    }
  }

  static String _generateCodeVerifier() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _codeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
