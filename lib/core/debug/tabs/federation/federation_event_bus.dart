import 'dart:async';

import 'package:flutter/foundation.dart';

enum DeliveryStatus { delivered, retrying, relayed, failed }

class OutgoingActivityEvent {
  const OutgoingActivityEvent({
    required this.timestamp,
    required this.destination,
    required this.activityType,
    required this.payloadJson,
    required this.httpStatus,
    required this.status,
  });

  final DateTime timestamp;
  final String destination;
  final String activityType;
  final String payloadJson;
  final int? httpStatus;
  final DeliveryStatus status;
}

class IncomingActivityEvent {
  const IncomingActivityEvent({
    required this.timestamp,
    required this.sourceActorUrl,
    required this.activityType,
    required this.signatureResult,
    required this.outcome,
  });

  final DateTime timestamp;
  final String sourceActorUrl;
  final String activityType;
  final String signatureResult; // verified | failed | missing | replayed
  final String outcome; // accepted | dropped | rate-limited | defederated
}

/// A simple in-memory event bus for the federation debug inspector.
/// Only instantiated in debug builds; no-ops in release.
class FederationEventBus {
  static final FederationEventBus instance = FederationEventBus._();
  FederationEventBus._();

  final _outgoing = StreamController<OutgoingActivityEvent>.broadcast();
  final _incoming = StreamController<IncomingActivityEvent>.broadcast();

  Stream<OutgoingActivityEvent> get outgoing => _outgoing.stream;
  Stream<IncomingActivityEvent> get incoming => _incoming.stream;

  void emitOutgoing(OutgoingActivityEvent event) {
    if (kDebugMode) _outgoing.add(event);
  }

  void emitIncoming(IncomingActivityEvent event) {
    if (kDebugMode) _incoming.add(event);
  }
}
