import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

typedef HandlerFactory = Handler Function();

/// Runs a shelf HTTP server in the main isolate on a system-assigned port.
/// The server is intentionally kept in the main isolate so it can access
/// Drift / GetIt singletons without cross-isolate marshalling.
/// Isolate isolation is deferred to a future optimisation if profiling shows it
/// is needed.
class FederationServer {
  FederationServer();

  HttpServer? _server;
  int? _port;

  int? get currentPort => _port;
  String? get currentAddress => _server?.address.address;

  Future<void> start({required Router router}) async {
    if (_server != null) return;

    final handler = const Pipeline()
        .addMiddleware(_httpsEnforcementMiddleware())
        .addMiddleware(_sizeLimitMiddleware(maxBytes: 64 * 1024))
        .addHandler(router.call);

    _server = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      0, // system-assigned port
    );
    _port = _server!.port;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _port = null;
  }
}

/// Rejects requests that arrive over HTTP (non-HTTPS).
/// In production the device is behind a TLS-terminating relay, so this
/// middleware acts as a safety net for direct LAN connections.
Middleware _httpsEnforcementMiddleware() {
  return (Handler inner) {
    return (Request request) {
      if (request.requestedUri.scheme == 'http') {
        final httpsUri = request.requestedUri.replace(scheme: 'https');
        return Response.movedPermanently(httpsUri.toString());
      }
      return inner(request);
    };
  };
}

/// Reads the Content-Length header and refuses bodies exceeding [maxBytes]
/// before routing. Streams without Content-Length are let through and rely on
/// per-handler body reading to detect oversize.
Middleware _sizeLimitMiddleware({required int maxBytes}) {
  return (Handler inner) {
    return (Request request) {
      final contentLength = request.contentLength;
      if (contentLength != null && contentLength > maxBytes) {
        return Response(
          HttpStatus.requestEntityTooLarge,
          body: 'Payload too large',
        );
      }
      return inner(request);
    };
  };
}
