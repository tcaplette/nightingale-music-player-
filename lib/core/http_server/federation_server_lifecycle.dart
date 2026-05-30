import 'package:flutter/widgets.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/http_server/federation_router.dart';
import 'package:nightingale/core/http_server/federation_server.dart';
import 'package:nightingale/core/logging/app_logger.dart';

/// Binds the [FederationServer] to app lifecycle events.
/// Mount this widget near the root of the widget tree.
class FederationServerLifecycle extends StatefulWidget {
  const FederationServerLifecycle({super.key, required this.child});
  final Widget child;

  @override
  State<FederationServerLifecycle> createState() =>
      _FederationServerLifecycleState();
}

class _FederationServerLifecycleState extends State<FederationServerLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
