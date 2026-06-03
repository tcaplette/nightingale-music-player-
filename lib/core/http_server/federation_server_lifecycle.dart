import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/http_server/federation_router.dart';
import 'package:nightingale/core/http_server/federation_server.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/reachability/node_reachability_service.dart';
import 'package:nightingale/features/federation/stun/stun_address_resolver.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

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
    Future(() async {
      try {
        final stun = sl<StunAddressResolver>();
        final publicAddress = await stun.resolve();
        final identityRepo = sl<NodeIdentityRepository>();
        await identityRepo.updatePublicAddress(publicAddress);
        AppLogger.debug(
          'Public address updated: $publicAddress',
          tag: 'server',
        );
      } catch (e) {
        AppLogger.debug('Public address refresh failed: $e', tag: 'server');
      }
    }).ignore();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final server = sl<FederationServer>();
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        server.stop();
        AppLogger.debug('FederationServer stopped (app paused)', tag: 'server');
      case AppLifecycleState.resumed:
        _restart(server);
      default:
        break;
    }
  }

  Future<void> _restart(FederationServer server) async {
    try {
      await server.start(router: buildFederationRouter());
      AppLogger.debug(
        'FederationServer started on port ${server.currentPort}',
        tag: 'server',
      );
    } catch (e) {
      AppLogger.error('FederationServer failed to start: $e', tag: 'server');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
