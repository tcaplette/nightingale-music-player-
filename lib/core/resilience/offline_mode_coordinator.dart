import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Authoritative online/offline state for the whole app.
/// All features that need to know about connectivity watch this provider.
/// On transition to online, app.dart triggers ActivityQueueService.flush().
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  // Emit current state immediately before listening to changes.
  final initial = await connectivity.checkConnectivity();
  yield _isConnected(initial);

  yield* connectivity.onConnectivityChanged.map(_isConnected);
});

bool _isConnected(List<ConnectivityResult> results) {
  return results.any((r) =>
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.ethernet ||
      r == ConnectivityResult.vpn);
}
