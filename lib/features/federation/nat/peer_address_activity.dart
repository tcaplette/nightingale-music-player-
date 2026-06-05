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
  });

  final String id;
  final String fromActorUrl;
  final String toActorUrl;
  final String sessionNonce;
  final String publicAddress;
  final String localAddress;
  final DateTime timestamp;

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
        },
      };
}
