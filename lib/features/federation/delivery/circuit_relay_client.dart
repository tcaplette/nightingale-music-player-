import 'package:nightingale/core/activitypub/models/ap_activity.dart';

/// Integration point for a future volunteer circuit relay network.
/// No implementation is registered in the service locator in this phase.
abstract class CircuitRelayClient {
  Future<bool> relay(ApActivity activity, String targetInboxUrl);
}
