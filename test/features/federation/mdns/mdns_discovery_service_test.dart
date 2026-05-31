import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/features/federation/mdns/mdns_discovery_service.dart';

void main() {
  group('MdnsDiscoveryService', () {
    test('lookup returns null when no peer is registered', () {
      final svc = MdnsDiscoveryService();
      expect(svc.lookup('/users/alice'), isNull);
    });

    test('resolve returns null for unknown actor URL', () {
      final svc = MdnsDiscoveryService();
      expect(svc.resolve('http://192.168.1.10:7777/users/alice'), isNull);
    });

    test('hasPeer returns false when no peer is registered', () {
      final svc = MdnsDiscoveryService();
      expect(svc.hasPeer('http://192.168.1.10:7777/users/alice'), isFalse);
    });

    test('peers is empty on construction', () {
      final svc = MdnsDiscoveryService();
      expect(svc.peers, isEmpty);
    });
  });

  group('MdnsPeer', () {
    test('actorUrl is constructed correctly', () {
      const peer = MdnsPeer(ip: '192.168.1.10', port: 7777, username: 'alice');
      expect(peer.actorUrl, 'http://192.168.1.10:7777/users/alice');
    });
  });
}
