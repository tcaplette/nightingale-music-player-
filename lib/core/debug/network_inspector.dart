/// In-app network request inspector (debug builds only).
/// Wired into the HTTP client layer so diagnostic tabs can surface stats.
class NetworkInspector {
  const NetworkInspector();

  // Accumulated counters — reset on app restart.
  static int _totalRequests = 0;
  static int _totalBytesReceived = 0;

  // Populated when Phase 3 wires HTTP clients through this inspector.
  List<Object> get requests => const [];

  int get totalRequestCount => _totalRequests;
  int get totalBytesReceived => _totalBytesReceived;

  void recordRequest({required int responseSizeBytes}) {
    _totalRequests++;
    _totalBytesReceived += responseSizeBytes;
  }
}
