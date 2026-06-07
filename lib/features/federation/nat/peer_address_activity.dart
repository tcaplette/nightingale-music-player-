import 'package:nightingale/core/activitypub/ap_context.dart';
import 'package:nightingale/core/activitypub/models/ap_activity.dart';

/// Typed model for a PeerAddress ActivityPub activity used as a hole-punch
/// signaling packet. Wraps [ApPeerAddress] with strongly-typed object fields.
class PeerAddressActivity {
  const PeerAddressActivity({
    required this.id,
    required this.fromActorUrl,
    required this.toActorUrl,
    required this.sessionNonce,
    required this.publicAddress,
    required this.localAddress,
    required this.timestamp,
    this.senderMastodonHandle,
  });

  final String id;
  final String fromActorUrl;
  final String toActorUrl;
  final String sessionNonce;
  final String publicAddress;
  final String localAddress;
  final DateTime timestamp;
  // Sender's Mastodon handle (@user@instance.tld) carried so the receiver
  // can echo back via Mastodon DM when both devices are behind CGNAT.
  final String? senderMastodonHandle;

  static PeerAddressActivity? fromSignalJson(Map<String, dynamic> json) {
    try {
      final nonce = json['n'] as String?;
      final fromActorUrl = json['f'] as String?;
      final publicAddress = json['p'] as String?;
      if (nonce == null || fromActorUrl == null || publicAddress == null) {
        return null;
      }
      return PeerAddressActivity(
        id: '$fromActorUrl/peer-address-dm/$nonce',
        fromActorUrl: fromActorUrl,
        toActorUrl: '',
        sessionNonce: nonce,
        publicAddress: publicAddress,
        localAddress: publicAddress,
        timestamp: DateTime.now().toUtc(),
        senderMastodonHandle: json['s'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static PeerAddressActivity? fromJson(Map<String, dynamic> json) {
    try {
      final activity = ApPeerAddress.fromJson(json);
      return fromApActivity(activity);
    } catch (_) {
      return null;
    }
  }

  static PeerAddressActivity? fromApActivity(ApPeerAddress activity) {
    final obj = activity.object;
    if (obj is! Map) return null;
    final sessionNonce = obj['sessionNonce'] as String?;
    final publicAddress = obj['publicAddress'] as String?;
    final localAddress = obj['localAddress'] as String?;
    final timestampStr = obj['timestamp'] as String?;
    final to = activity.to;
    if (sessionNonce == null ||
        publicAddress == null ||
        localAddress == null ||
        timestampStr == null ||
        to == null ||
        to.isEmpty) {
      return null;
    }
    return PeerAddressActivity(
      id: activity.id,
      fromActorUrl: activity.actor,
      toActorUrl: to.first,
      sessionNonce: sessionNonce,
      publicAddress: publicAddress,
      localAddress: localAddress,
      timestamp: DateTime.parse(timestampStr),
      senderMastodonHandle: obj['senderMastodonHandle'] as String?,
    );
  }

  ApPeerAddress toApActivity() => ApPeerAddress(
        id: id,
        actor: fromActorUrl,
        object: {
          'type': 'PeerAddressObject',
          'sessionNonce': sessionNonce,
          'publicAddress': publicAddress,
          'localAddress': localAddress,
          'timestamp': timestamp.toUtc().toIso8601String(),
          if (senderMastodonHandle != null)
            'senderMastodonHandle': senderMastodonHandle,
        },
        to: [toActorUrl],
      );

  Map<String, dynamic> toJson() => {
        '@context': kDefaultApContext,
        'id': id,
        'type': 'PeerAddress',
        'actor': fromActorUrl,
        'to': [toActorUrl],
        'object': {
          'type': 'PeerAddressObject',
          'sessionNonce': sessionNonce,
          'publicAddress': publicAddress,
          'localAddress': localAddress,
          'timestamp': timestamp.toUtc().toIso8601String(),
          if (senderMastodonHandle != null)
            'senderMastodonHandle': senderMastodonHandle,
        },
      };
}
