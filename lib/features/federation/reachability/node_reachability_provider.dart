import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/reachability/node_reachability_service.dart';
import 'package:nightingale/features/federation/reachability/reachability_state.dart';

/// Riverpod provider for node reachability state.
final nodeReachabilityProvider =
    StateNotifierProvider<NodeReachabilityNotifier, ReachabilityState>(
  (ref) => NodeReachabilityNotifier(),
);

class NodeReachabilityNotifier extends StateNotifier<ReachabilityState> {
  NodeReachabilityNotifier() : super(ReachabilityOffline()) {
    _checkStatus();
  }

  final NodeReachabilityService _service = sl<NodeReachabilityService>();

  Future<void> _checkStatus() async {
    // TODO: Implement actual reachability check against a known relay or peer
    // For now, mark as offline since we don't have a registration mechanism yet
    state = ReachabilityOffline();
  }

  void setRegistered(String address, int port) {
    state = ReachabilityRegistered(address: address, port: port);
  }

  void setFailed(String reason) {
    state = ReachabilityFailed(reason);
  }

  void setOffline() {
    state = ReachabilityOffline();
  }
}
