import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/http_server/federation_server.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/network/network_binding_service.dart';
import 'package:nightingale/features/federation/reachability/node_reachability_service.dart';

/// Binds the [FederationServer] to app lifecycle events and listens for
/// network changes to keep the node's advertised address current.
class FederationServerLifecycle extends StatefulWidget {
  const FederationServerLifecycle({super.key, required this.child});
  final Widget child;

  @override
  State<FederationServerLifecycle> createState() =>
      _FederationServerLifecycleState();
}

class _FederationServerLifecycleState extends State<FederationServerLifecycle>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscribeToNetworkChanges();
    _refreshPublicAddress();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _subscribeToNetworkChanges() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    AppLogger.debug(
      'Network change: ${results.map((r) => r.name).join(', ')}',
      tag: 'server',
    );

    // Clear stale reachability cache.
    try {
      sl<NodeReachabilityService>().clearCache();
    } catch (_) {}

    // Re-run STUN and update stored public address.
    _refreshPublicAddress();
  }

  void _refreshPublicAddress() {
    sl<NetworkBindingService>().evaluateAndBind().ignore();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        sl<FederationServer>().stop();
        AppLogger.debug('FederationServer stopped (app paused)', tag: 'server');
      case AppLifecycleState.resumed:
        _refreshPublicAddress();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
