import 'dart:async';
import 'dart:io';

import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/settings/data/settings_repository.dart';

const _tag = 'relay_server';
const _sessionPairTimeout = Duration(seconds: 30);

class _RelayPeer {
  _RelayPeer(this.socket);
  final Socket socket;
  bool paired = false;
}

/// Plain TCP relay server that pipes bytes between two peers sharing a session
/// ID. Runs on [preferredPort + 1] (e.g. 7778) independently of the shelf HTTP
/// server so the relay socket can be used as a raw byte pipe.
///
/// Protocol:
///   Client sends one line: `<ROLE> <sessionId>\n`
///   where ROLE is "REQUESTER" or "SERVER".
///   Server responds: `OK\n` (paired) or `WAIT\n` (first peer, waiting).
///   After OK, bytes are piped bidirectionally until either side disconnects.
class RelayServer {
  RelayServer({required this.port, required SettingsRepository settings})
      : _settings = settings;

  final int port;
  final SettingsRepository _settings;

  ServerSocket? _server;
  final _waiting = <String, _RelayPeer>{};
  final _timeouts = <String, Timer>{};

  Future<void> start() async {
    if (_server != null) return;
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_handleSocket);
    AppLogger.info('RelayServer: listening on port $port', tag: _tag);
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    for (final t in _timeouts.values) {
      t.cancel();
    }
    _timeouts.clear();
    _waiting.clear();
  }

  void _handleSocket(Socket socket) async {
    final enabled = await _settings.isRelayModeEnabled();
    if (!enabled) {
      AppLogger.debug(
        'RelayServer: rejected connection — relay mode is disabled',
        tag: _tag,
      );
      socket.destroy();
      return;
    }

    try {
      final line = await _readLine(socket)
          .timeout(const Duration(seconds: 10));
      final parts = line.split(' ');
      if (parts.length != 2) {
        socket.destroy();
        return;
      }
      final role = parts[0];
      final sessionId = parts[1];

      if (role != 'REQUESTER' && role != 'SERVER') {
        AppLogger.warning(
          'RelayServer: invalid role "$role" in handshake — closing connection',
          tag: _tag,
        );
        socket.destroy();
        return;
      }

      final peer = _RelayPeer(socket);
      final waiting = _waiting[sessionId];

      if (waiting == null) {
        // First peer — store and wait.
        _waiting[sessionId] = peer;
        socket.write('WAIT\n');
        AppLogger.info(
          'RelayServer: session=$sessionId $role waiting',
          tag: _tag,
        );

        _timeouts[sessionId] = Timer(_sessionPairTimeout, () {
          final w = _waiting.remove(sessionId);
          _timeouts.remove(sessionId);
          if (w != null && !w.paired) {
            AppLogger.info(
              'RelayServer: session=$sessionId timed out',
              tag: _tag,
            );
            w.socket.destroy();
          }
        });
      } else {
        // Second peer — pair and pipe.
        _timeouts.remove(sessionId)?.cancel();
        _waiting.remove(sessionId);
        waiting.paired = true;
        peer.paired = true;

        socket.write('OK\n');
        waiting.socket.write('OK\n');

        AppLogger.info(
          'RelayServer: session=$sessionId paired — piping',
          tag: _tag,
        );

        socket.listen(
          waiting.socket.add,
          onDone: () {
            AppLogger.debug(
              'RelayServer: session=$sessionId requester disconnected',
              tag: _tag,
            );
            waiting.socket.destroy();
          },
          onError: (Object e) {
            AppLogger.debug(
              'RelayServer: session=$sessionId requester socket error: $e',
              tag: _tag,
            );
            waiting.socket.destroy();
          },
        );
        waiting.socket.listen(
          socket.add,
          onDone: () {
            AppLogger.debug(
              'RelayServer: session=$sessionId server disconnected',
              tag: _tag,
            );
            socket.destroy();
          },
          onError: (Object e) {
            AppLogger.debug(
              'RelayServer: session=$sessionId server socket error: $e',
              tag: _tag,
            );
            socket.destroy();
          },
        );
      }
    } catch (e) {
      AppLogger.debug('RelayServer: socket error: $e', tag: _tag);
      socket.destroy();
    }
  }

  Future<String> _readLine(Socket socket) async {
    final buffer = StringBuffer();
    await for (final chunk in socket.cast<List<int>>()) {
      for (final byte in chunk) {
        if (byte == 10 /* \n */) return buffer.toString().trim();
        buffer.writeCharCode(byte);
      }
    }
    return buffer.toString().trim();
  }
}
