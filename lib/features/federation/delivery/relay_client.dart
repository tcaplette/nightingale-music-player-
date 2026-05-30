import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nightingale/core/activitypub/models/ap_activity.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/core/logging/app_logger.dart';

class RelayClient {
  RelayClient({
    required this.relayBaseUrl,
    this.sigService,
  });

  final String relayBaseUrl;
  final HttpSignatureService? sigService;

  Future<String?> handOff(ApActivity activity, String targetActorUrl) async {
    if (relayBaseUrl.isEmpty) {
      AppLogger.debug(
        'RelayClient: no relay configured, skipping handoff',
        tag: 'relay',
      );
      return null;
    }
    try {
      final response = await http.post(
        Uri.parse('$relayBaseUrl/deliver'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'targetActorUrl': targetActorUrl,
          'payload': activity.toJson(),
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['referenceId'] as String?;
      }
      AppLogger.warning(
        'RelayClient: relay returned ${response.statusCode}',
        tag: 'relay',
      );
      return null;
    } catch (e) {
      AppLogger.error('RelayClient: handoff error: $e', tag: 'relay');
      return null;
    }
  }

  /// Requests a stream forwarding URL from the relay.
  /// Returns the relay stream URL if available, null otherwise.
  Future<String?> requestStreamForward({
    required String targetActorUrl,
    required String trackId,
  }) async {
    if (relayBaseUrl.isEmpty) {
      AppLogger.debug('RelayClient: no relay configured, skipping stream forward', tag: 'relay');
      return null;
    }

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$relayBaseUrl/stream-forward'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/json';
      request.body = jsonEncode({
        'targetActorUrl': targetActorUrl,
        'trackId': trackId,
      });

      // Sign the request if we have a signature service
      final signedRequest = sigService != null
          ? await sigService!.signRequest(request)
          : request;

      final client = http.Client();
      final response = await client.send(signedRequest).then(http.Response.fromStream);
      client.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final url = json['streamUrl'] as String?;
        AppLogger.info('RelayClient: got stream forward URL: $url', tag: 'relay');
        return url;
      }

      AppLogger.warning(
        'RelayClient: stream forward returned ${response.statusCode}',
        tag: 'relay',
      );
      return null;
    } catch (e) {
      AppLogger.error('RelayClient: stream forward error: $e', tag: 'relay');
      return null;
    }
  }
}
