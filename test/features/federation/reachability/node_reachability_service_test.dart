import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/features/federation/reachability/node_reachability_service.dart';

void main() {
  group('NodeReachabilityService.resolveProbeUrl', () {
    const actorUrl = 'http://192.168.1.20:7777/users/bob';

    test('STUN address provided — uses STUN address', () {
      final svc = NodeReachabilityService();
      final probeUrl = svc.resolveProbeUrl(actorUrl, '203.0.113.5:7777');
      expect(probeUrl, 'http://203.0.113.5:7777');
    });

    test('no STUN address — falls back to stored actor URL host', () {
      final svc = NodeReachabilityService();
      final probeUrl = svc.resolveProbeUrl(actorUrl, null);
      expect(probeUrl, 'http://192.168.1.20:7777');
    });

    test('empty STUN address — falls back to stored actor URL host', () {
      final svc = NodeReachabilityService();
      final probeUrl = svc.resolveProbeUrl(actorUrl, '');
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
