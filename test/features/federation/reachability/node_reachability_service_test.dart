import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/features/federation/mdns/mdns_discovery_service.dart';
import 'package:nightingale/features/federation/reachability/node_reachability_service.dart';

/// Fake mDNS discovery service backed by a fixed map.
class _FakeMdns extends MdnsDiscoveryService {
  _FakeMdns(this._peers);
  final Map<String, MdnsPeer> _peers;

  @override
  MdnsPeer? resolve(String actorUrl) {
    final path = Uri.parse(actorUrl).path;
    return _peers[path];
  }
}

void main() {
  group('NodeReachabilityService.resolveProbeUrl', () {
    const actorUrl = 'http://192.168.1.20:7777/users/bob';

    test('mDNS hit — uses mDNS address', () {
      final mdns = _FakeMdns({
        '/users/bob': MdnsPeer(ip: '192.168.1.20', port: 7777, username: 'bob'),
      });
      final svc = NodeReachabilityService(mdns: mdns);

      final probeUrl = svc.resolveProbeUrl(actorUrl, null);
      expect(probeUrl, 'http://192.168.1.20:7777');
    });

    test('mDNS miss + STUN address provided — uses STUN address', () {
      final mdns = _FakeMdns({});
      final svc = NodeReachabilityService(mdns: mdns);

      final probeUrl = svc.resolveProbeUrl(actorUrl, '203.0.113.5:7777');
      expect(probeUrl, 'http://203.0.113.5:7777');
    });

    test('both miss — falls back to stored actor URL host', () {
      final mdns = _FakeMdns({});
      final svc = NodeReachabilityService(mdns: mdns);

      final probeUrl = svc.resolveProbeUrl(actorUrl, null);
      expect(probeUrl, 'http://192.168.1.20:7777');
    });
  });

  group('NodeReachabilityService.clearCache', () {
    test('clearCache does not throw', () {
      final svc = NodeReachabilityService();
      expect(() => svc.clearCache(), returnsNormally);
    });
  });
}
