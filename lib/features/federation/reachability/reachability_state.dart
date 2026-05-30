sealed class ReachabilityState {}

class ReachabilityRegistered extends ReachabilityState {
  ReachabilityRegistered({required this.address, required this.port});
  final String address;
  final int port;
}

class ReachabilityPending extends ReachabilityState {}

class ReachabilityFailed extends ReachabilityState {
  ReachabilityFailed(this.reason);
  final String reason;
}

class ReachabilityOffline extends ReachabilityState {}
