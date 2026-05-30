import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart' as shelf;
import 'package:nightingale/core/crypto/crypto_service.dart';
import 'package:nightingale/core/logging/app_logger.dart';

sealed class SignatureResult {}

class SignatureVerified extends SignatureResult {}

class SignatureMissing extends SignatureResult {}

class SignatureFailed extends SignatureResult {
  SignatureFailed(this.reason);
  final String reason;
}

class SignatureReplayed extends SignatureResult {
  SignatureReplayed(this.nonce);
  final String nonce;
}

class HttpSignatureService {
  HttpSignatureService({
    required this.crypto,
    required this.keyId,
    this.timeWindowSeconds = 30,
    this.nonceTtlSeconds = 60,
  }) {
    _startNonceCleanup();
  }

  final CryptoService crypto;
  final String keyId;
  final int timeWindowSeconds;
  final int nonceTtlSeconds;

  // In-memory nonce store: nonce → timestamp of first receipt
  final Map<String, DateTime> _nonces = {};

  // ── Signing ───────────────────────────────────────────────────────────────

  Future<http.Request> signRequest(http.Request request) async {
    final date = HttpDate.format(DateTime.now().toUtc());
    final bodyBytes = await request.finalize().toBytes();
    final digest = 'SHA-256=' + base64.encode(sha256.convert(bodyBytes).bytes);

    final signingString = _buildSigningString(
      method: request.method.toLowerCase(),
      path: request.url.path.isNotEmpty ? request.url.path : '/',
      query: request.url.query.isNotEmpty ? '?${request.url.query}' : '',
      host: request.url.host,
      date: date,
      digest: digest,
    );

    final sigBytes = await crypto.sign(utf8.encode(signingString));
    final sigB64 = base64.encode(sigBytes);

    final sigHeader =
        'keyId="$keyId",algorithm="ed25519",headers="(request-target) host date digest",signature="$sigB64"';

    return http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..headers[HttpHeaders.dateHeader] = date
      ..headers['digest'] = digest
      ..headers['signature'] = sigHeader
      ..bodyBytes = bodyBytes;
  }

  // ── Verification ──────────────────────────────────────────────────────────

  Future<SignatureResult> verifyRequest(shelf.Request request) async {
    final sigHeader = request.headers['signature'];
    if (sigHeader == null) return SignatureMissing();

    // Time window check
    final dateStr = request.headers[HttpHeaders.dateHeader];
    if (dateStr == null) return SignatureFailed('missing Date header');
    try {
      final requestDate = HttpDate.parse(dateStr);
      final diff = DateTime.now().toUtc().difference(requestDate).abs();
      if (diff.inSeconds > timeWindowSeconds) {
        return SignatureFailed(
          'Date out of window: ${diff.inSeconds}s > ${timeWindowSeconds}s',
        );
      }
    } catch (_) {
      return SignatureFailed('unparseable Date header');
    }

    // Parse Signature header fields
    final fields = _parseSignatureHeader(sigHeader);
    final sigKeyId = fields['keyId'];
    final sigB64 = fields['signature'];
    final signedHeaders = fields['headers'] ?? '(request-target) host date';

    if (sigKeyId == null || sigB64 == null) {
      return SignatureFailed('malformed Signature header');
    }

    // Nonce / replay check (optional — use request ID or nonce field if present)
    final nonce = fields['nonce'];
    if (nonce != null) {
      if (_nonces.containsKey(nonce)) {
        AppLogger.debug(
          'Replay rejected: nonce=$nonce',
          tag: 'http_sig',
        );
        return SignatureReplayed(nonce);
      }
      _nonces[nonce] = DateTime.now().toUtc();
    }

    // Fetch public key from actor URL (keyId is the actor key URL)
    final publicKeyPem = await _fetchPublicKey(sigKeyId);
    if (publicKeyPem == null) {
      return SignatureFailed('could not fetch public key for $sigKeyId');
    }

    // Reconstruct signing string
    final path = request.requestedUri.path.isNotEmpty
        ? request.requestedUri.path
        : '/';
    final query = request.requestedUri.query.isNotEmpty
        ? '?${request.requestedUri.query}'
        : '';
    final method = request.method.toLowerCase();

    final components = signedHeaders.split(' ').map((h) {
      return switch (h) {
        '(request-target)' => '(request-target): $method $path$query',
        'host' => 'host: ${request.requestedUri.host}',
        'date' => 'date: ${request.headers[HttpHeaders.dateHeader] ?? ''}',
        'digest' => 'digest: ${request.headers['digest'] ?? ''}',
        _ => '$h: ${request.headers[h] ?? ''}',
      };
    });
    final signingString = components.join('\n');

    // Verify
    try {
      final pubBytes = _parsePemPublicKeyBytes(publicKeyPem);
      final pubKey = SimplePublicKey(pubBytes, type: KeyPairType.ed25519);
      final sigBytes = base64.decode(sigB64);
      final sig = Signature(sigBytes, publicKey: pubKey);
      final valid = await Ed25519().verify(utf8.encode(signingString), signature: sig);
      if (!valid) return SignatureFailed('signature mismatch');
      return SignatureVerified();
    } catch (e) {
      return SignatureFailed('verification error: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _buildSigningString({
    required String method,
    required String path,
    required String query,
    required String host,
    required String date,
    required String digest,
  }) =>
      '(request-target): $method $path$query\n'
      'host: $host\n'
      'date: $date\n'
      'digest: $digest';

  Map<String, String> _parseSignatureHeader(String header) {
    final result = <String, String>{};
    final regex = RegExp(r'(\w+)="([^"]*)"');
    for (final match in regex.allMatches(header)) {
      result[match.group(1)!] = match.group(2)!;
    }
    return result;
  }

  Future<String?> _fetchPublicKey(String keyId) async {
    try {
      final actorUrl = keyId.split('#').first;
      final response = await http.get(
        Uri.parse(actorUrl),
        headers: {'Accept': 'application/activity+json'},
      );
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final pk = json['publicKey'];
      if (pk is Map) return pk['publicKeyPem'] as String?;
      return null;
    } catch (_) {
      return null;
    }
  }

  List<int> _parsePemPublicKeyBytes(String pem) {
    final lines = pem.split('\n').where((l) => !l.startsWith('-----')).join();
    final der = base64.decode(lines);
    return der.sublist(12); // 12-byte SPKI prefix; raw Ed25519 key follows
  }

  void _startNonceCleanup() {
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: nonceTtlSeconds));
      final cutoff =
          DateTime.now().toUtc().subtract(Duration(seconds: nonceTtlSeconds));
      _nonces.removeWhere((_, ts) => ts.isBefore(cutoff));
      return true;
    });
  }
}
