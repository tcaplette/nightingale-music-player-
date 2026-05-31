import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

typedef HandlerFactory = Handler Function();

/// Runs a shelf HTTP server in the main isolate on a stable configured port.
/// The server is intentionally kept in the main isolate so it can access
/// Drift / GetIt singletons without cross-isolate marshalling.
class FederationServer {
  FederationServer({this.preferredPort = 7777});

  final int preferredPort;

  HttpServer? _server;
  int? _port;

  int? get currentPort => _port;
  String? get currentAddress => _server?.address.address;

  Future<void> start({required Router router}) async {
    if (_server != null) return;

    final handler = const Pipeline()
        .addMiddleware(_sizeLimitMiddleware(maxBytes: 64 * 1024))
        .addHandler(router.call);

    // Try preferred port, then +1 and +2 as fallback.
    final candidates = [preferredPort, preferredPort + 1, preferredPort + 2];
    HttpServer? bound;
    for (final port in candidates) {
      try {
        bound = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
        break;
      } on SocketException {
        // Port in use — try next.
      }
    }

    if (bound == null) {
      throw StateError(
        'FederationServer: all candidate ports '
        '${candidates.join(', ')} are in use.',
      );
    }

    _server = bound;
    _port = bound.port;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _port = null;
  }
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
