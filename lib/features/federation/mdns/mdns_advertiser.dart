import 'package:bonsoir/bonsoir.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/mdns/mdns_event_log.dart';

const _serviceType = '_nightingale._tcp';
const _tag = 'mdns_advertiser';

class MdnsAdvertiser {
  MdnsAdvertiser({required this.username, required this.port});

  final String username;
  final int port;

  BonsoirBroadcast? _broadcast;
  bool get isRunning => _broadcast != null;

  Future<void> start() async {
    if (_broadcast != null) return;
    _log('Starting broadcast: $username.$_serviceType port=$port');
    try {
      final service = BonsoirService(
        name: username,
        type: _serviceType,
        port: port,
      );
      final broadcast = BonsoirBroadcast(service: service);
      await broadcast.ready;
      _log('Broadcast ready');

      broadcast.eventStream?.listen((event) {
        _log('Broadcast event: ${event.type} — ${event.service?.name}');
      });

      await broadcast.start();
      _broadcast = broadcast;
      _log('Broadcast started successfully ✓');
    } catch (e, st) {
      _log('Broadcast FAILED: $e');
      AppLogger.error('mDNS advertiser start failed: $e\n$st', tag: _tag);
      _broadcast = null;
    }
  }

  Future<void> stop() async {
    if (_broadcast == null) return;
    _log('Stopping broadcast');
    try {
      await _broadcast!.stop();
      _log('Broadcast stopped');
    } catch (e) {
      _log('Broadcast stop error: $e');
    } finally {
      _broadcast = null;
    }
  }

  void _log(String msg) {
    AppLogger.debug(msg, tag: _tag);
    MdnsEventLog.instance.log('[ADV] $msg');
  }
}
