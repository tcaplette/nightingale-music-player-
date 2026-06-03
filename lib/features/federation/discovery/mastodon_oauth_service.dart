import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/onboarding/secure_storage_service.dart';

const _tag = 'mastodon_oauth';
const _redirectUri = 'nightingale://oauth/callback';
const _scopes = 'read:follows read:accounts';
const _clientName = 'Nightingale';

class MastodonAccountDetails {
  const MastodonAccountDetails({
    required this.username,
    required this.displayName,
    required this.handle,
    required this.instance,
    this.avatarUrl,
  });
  final String username;
  final String displayName;
  final String handle;
  final String instance;
  final String? avatarUrl;
}

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

/// Intermediate result returned by [MastodonOAuthService.prepareSignIn].
/// Contains everything needed to show the auth page and later complete the flow.
class OAuthPrepared {
  const OAuthPrepared({
    required this.instance,
    required this.authUrl,
    required this.state,
    required this.codeVerifier,
  });
  final String instance;
  final String authUrl;
  final String state;
  final String codeVerifier;
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

  /// Step 1 of the OAuth flow: normalises the instance, registers the app,
  /// and builds the authorization URL with PKCE parameters.
  ///
  /// The caller is responsible for showing the URL to the user (e.g. via
  /// [MastodonAuthWebView]) and collecting the callback URL.
  /// Pass the result to [completeSignIn] once the user has authenticated.
  Future<OAuthPrepared?> prepareSignIn(String handleOrInstance) async {
    final instance = _normaliseInstance(handleOrInstance);
    if (instance.isEmpty) return null;

    AppLogger.debug('Preparing PKCE OAuth for $instance', tag: _tag);

    final creds = await _ensureClientCredentials(instance);
    if (creds == null) return null;

    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _codeChallenge(codeVerifier);
    final state = _generateState();

    final authUrl = Uri.https(
      instance,
      '/oauth/authorize',
      {
        'client_id': creds.clientId,
        'redirect_uri': _redirectUri,
        'response_type': 'code',
        'scope': _scopes,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    ).toString();

    return OAuthPrepared(
      instance: instance,
      authUrl: authUrl,
      state: state,
      codeVerifier: codeVerifier,
    );
  }

  /// Step 2 of the OAuth flow: exchanges the authorization code from
  /// [callbackUrl] for an access token, validates state, and persists the token.
  Future<OAuthResult> completeSignIn(
    OAuthPrepared prepared,
    String? callbackUrl,
  ) async {
    AppLogger.debug('completeSignIn called — callbackUrl: ${callbackUrl ?? "null"}', tag: _tag);

    if (callbackUrl == null) {
      AppLogger.debug('completeSignIn: no callbackUrl → OAuthCancelled', tag: _tag);
      return OAuthCancelled();
    }

    final uri = Uri.parse(callbackUrl);
    final returnedState = uri.queryParameters['state'];
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];

    AppLogger.debug('completeSignIn parsed callback — code: ${code != null ? "present" : "missing"}, state match: ${returnedState == prepared.state}, error: $error', tag: _tag);

    if (error != null) {
      AppLogger.debug('completeSignIn: server returned error=$error', tag: _tag);
      return OAuthFailed('Sign-in was denied by your Mastodon server.');
    }

    if (returnedState != prepared.state) {
      AppLogger.warning('OAuth state mismatch — possible CSRF attack', tag: _tag);
      return OAuthFailed('Sign-in failed for security reasons. Please try again.');
    }

    if (code == null || code.isEmpty) {
      AppLogger.debug('completeSignIn: no auth code in callback', tag: _tag);
      return OAuthFailed('Sign-in failed. No authorisation code received.');
    }

    AppLogger.debug('completeSignIn: loading cached client credentials for ${prepared.instance}', tag: _tag);
    final creds = await _storage.getMastodonClientCredentials(prepared.instance);
    if (creds == null) {
      AppLogger.debug('completeSignIn: client credentials missing from storage', tag: _tag);
      return OAuthFailed('Sign-in failed. App credentials missing — please try again.');
    }

    try {
      AppLogger.debug('completeSignIn: posting to token endpoint on ${prepared.instance}', tag: _tag);
      final response = await _client.post(
        Uri.https(prepared.instance, '/oauth/token'),
        body: {
          'client_id': creds.clientId,
          'client_secret': creds.clientSecret,
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
          'code_verifier': prepared.codeVerifier,
        },
      ).timeout(const Duration(seconds: 10));

      AppLogger.debug('completeSignIn: token endpoint responded with ${response.statusCode}', tag: _tag);

      if (response.statusCode != 200) {
        AppLogger.debug('Token exchange failed body: ${response.body}', tag: _tag);
        return OAuthFailed('Sign-in failed. Your Mastodon server did not accept the authorisation code.');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = json['access_token'] as String?;
      if (accessToken == null) {
        AppLogger.debug('completeSignIn: access_token missing from response JSON', tag: _tag);
        return OAuthFailed('Sign-in failed. No access token received.');
      }

      await _storage.setMastodonAccessToken(prepared.instance, accessToken);
      AppLogger.debug('PKCE OAuth success for ${prepared.instance}', tag: _tag);
      return OAuthSuccess(instance: prepared.instance, accessToken: accessToken);
    } catch (e) {
      AppLogger.debug('Token exchange error: $e', tag: _tag);
      return OAuthFailed('Could not complete sign-in. Check your connection and try again.');
    }
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

  /// Returns the user's full account details from Mastodon after sign-in.
  Future<MastodonAccountDetails?> fetchAccountDetails(
    String instance,
    String accessToken,
  ) async {
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
      final displayName = (json['display_name'] as String?)?.trim();
      final avatarUrl = json['avatar'] as String?;
      if (username == null) return null;
      return MastodonAccountDetails(
        username: username,
        displayName: displayName?.isNotEmpty == true ? displayName! : username,
        handle: '@$username@$normalised',
        avatarUrl: avatarUrl,
        instance: normalised,
      );
    } catch (_) {
      return null;
    }
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

  static String _generateState() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
