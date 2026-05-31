import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/mdns/mdns_event_log.dart';

const _serviceType = '_nightingale._tcp';
const _tag = 'mdns_discovery';

class MdnsPeer {
  const MdnsPeer({
    required this.ip,
    required this.port,
    required this.username,
  });
  final String ip;
  final int port;
  final String username;

  String get actorUrl => 'http://$ip:$port/users/$username';
}

class MdnsDiscoveryService {
  final Map<String, MdnsPeer> _peers = {};
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _sub;

  Map<String, MdnsPeer> get peers => Map.unmodifiable(_peers);
  bool get isRunning => _discovery != null;

  MdnsPeer? lookup(String actorUrlPath) => _peers[actorUrlPath];

  bool hasPeer(String actorUrl) {
    final path = Uri.parse(actorUrl).path;
    return _peers.containsKey(path);
  }

  MdnsPeer? resolve(String actorUrl) {
    final path = Uri.parse(actorUrl).path;
    return _peers[path];
  }

  Future<void> startBrowsing() async {
    if (_discovery != null) return;
    _log('Starting discovery for $_serviceType');
    try {
      final discovery = BonsoirDiscovery(type: _serviceType);
      await discovery.ready;
      _log('Discovery ready');

      _sub = discovery.eventStream!.listen(_onEvent);
      await discovery.start();
      _discovery = discovery;
      _log('Discovery started ✓');
    } catch (e, st) {
      _log('Discovery FAILED: $e');
      AppLogger.error('mDNS discovery start failed: $e\n$st', tag: _tag);
      _discovery = null;
    }
  }

  Future<void> refresh() async {
    _log('Refreshing — clearing ${_peers.length} peers');
    await stop();
    _peers.clear();
    await startBrowsing();
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _discovery?.stop();
    } catch (_) {}
    _discovery = null;
    _log('Discovery stopped');
  }

  void _onEvent(BonsoirDiscoveryEvent event) {
    _log('Event: ${event.type} — service="${event.service?.name}" type="${event.service?.type}"');

    if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
      final service = event.service;
      if (service is ResolvedBonsoirService) {
        final ip = service.host;
        final port = service.port;
        final username = service.name;

        _log('Resolved: username=$username host=$ip port=$port');

        if (ip == null) {
          _log('WARNING: resolved service has null host — skipping');
          return;
        }

        final actorUrlPath = '/users/$username';
        _peers[actorUrlPath] = MdnsPeer(ip: ip, port: port, username: username);
        _log('Peer cached: $actorUrlPath → $ip:$port ✓');
      } else {
        _log('WARNING: resolved event has unexpected service type: ${service.runtimeType}');
      }
    } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
      final service = event.service;
      if (service != null) {
        final path = '/users/${service.name}';
        _peers.remove(path);
        _log('Peer lost: $path');
      }
    } else if (event.type == BonsoirDiscoveryEventType.discoveryStarted) {
      _log('Discovery confirmed started by platform');
    } else if (event.type == BonsoirDiscoveryEventType.discoveryStopped) {
      _log('Discovery stopped by platform');
    } else {
      _log('Unhandled event type: ${event.type}');
    }
  }

  void _log(String msg) {
    AppLogger.debug(msg, tag: _tag);
    MdnsEventLog.instance.log('[DIS] $msg');
  }
}
