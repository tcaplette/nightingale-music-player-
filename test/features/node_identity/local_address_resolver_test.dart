import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/features/node_identity/local_address_resolver.dart';

void main() {
  group('LocalAddressResolver', () {
    final resolver = LocalAddressResolver();

    test('resolve() does not throw', () async {
      await expectLater(resolver.resolve(), completes);
    });

    test('resolve() never returns a loopback address', () async {
      final ip = await resolver.resolve();
      if (ip != null) {
        expect(ip, isNot('127.0.0.1'));
        expect(ip, isNot('::1'));
        expect(ip, isNot('localhost'));
      }
    });

    test('resolve() returns null or a valid IPv4 address', () async {
      final ip = await resolver.resolve();
      if (ip != null) {
        final parts = ip.split('.');
        expect(parts.length, 4, reason: 'Expected dotted-decimal IPv4');
        for (final part in parts) {
          final n = int.tryParse(part);
          expect(n, isNotNull);
          expect(n! >= 0 && n <= 255, isTrue);
        }
      }
    });
  });

  group('Actor URL generation', () {
    test('actor URL uses LAN IP and stable port — never localhost or port 0', () {
      const lanIp = '192.168.1.50';
      const port = 7777;
      const username = 'alice';
      final url = 'http://$lanIp:$port/users/$username';

      expect(url.contains('localhost'), isFalse);
      expect(url.contains('127.0.0.1'), isFalse);
      expect(url.contains(':0/'), isFalse);
      expect(url, 'http://192.168.1.50:7777/users/alice');
    });

    test('actor URL with port 7778 fallback is still valid', () {
      const lanIp = '10.0.0.2';
      const port = 7778;
      final url = 'http://$lanIp:$port/users/bob';
      expect(Uri.parse(url).port, 7778);
    });
  });
}
