import 'dart:io';

import 'package:remote_network/remote_network.dart';
import 'package:test/test.dart';

void main() {
  test('iOS SSDP uses Wi-Fi and Ethernet interface names', () {
    for (final name in ['en0', 'en5']) {
      expect(SsdpDiscovery.isIosLanInterface(name), isTrue);
    }
    for (final name in ['pdp_ip0', 'utun2', 'awdl0', 'llw0', 'lo0']) {
      expect(SsdpDiscovery.isIosLanInterface(name), isFalse);
    }
  });
  final first = InternetAddress('192.168.1.10');
  final second = InternetAddress('10.0.0.10');
  SsdpAdvertisement advertisement(InternetAddress address) =>
      SsdpAdvertisement(address, {'usn': 'uuid:tv', 'st': 'service'});
  test(
    'a failed route does not discard a TV discovered on another interface',
    () async {
      final routes = <String>[];
      final discovery = SsdpDiscovery(
        addresses: () async => [first, second],
        searchRoute: (service, duration, address, cancelled) async {
          routes.add(address.address);
          if (address == second) {
            throw const SocketException('VPN route unavailable');
          }
          return [advertisement(address)];
        },
      );
      expect((await discovery.search('service')).single.identity, 'uuid:tv');
      expect(routes, containsAll([first.address, second.address]));
    },
  );
  test(
    'identical TV advertisements across interfaces are deduplicated',
    () async {
      final discovery = SsdpDiscovery(
        addresses: () async => [first, second],
        searchRoute: (service, duration, address, cancelled) async => [
          advertisement(address),
        ],
      );
      expect(await discovery.search('service'), hasLength(1));
    },
  );
  test(
    'all-route permission failures remain distinguishable from no TVs found',
    () async {
      final discovery = SsdpDiscovery(
        addresses: () async => [first, second],
        searchRoute: (service, duration, address, cancelled) async {
          throw const SocketException(
            'Denied',
            osError: OSError('Permission denied', 13),
          );
        },
      );
      await expectLater(
        discovery.search('service'),
        throwsA(
          isA<SocketException>().having(
            (error) => error.osError?.errorCode,
            'errno',
            13,
          ),
        ),
      );
      final empty = SsdpDiscovery(
        addresses: () async => [first],
        searchRoute: (service, duration, address, cancelled) async => [],
      );
      expect(await empty.search('service'), isEmpty);
    },
  );
  test('an empty interface does not hide a permission failure', () async {
    final discovery = SsdpDiscovery(
      addresses: () async => [first, second],
      searchRoute: (_, _, address, _) async {
        if (address == first) {
          return [];
        }
        throw const SocketException('Denied', osError: OSError('Denied', 13));
      },
    );
    await expectLater(
      discovery.search('service'),
      throwsA(
        isA<SocketException>().having(
          (error) => error.osError?.errorCode,
          'errno',
          13,
        ),
      ),
    );
  });

  test('no active IPv4 interface produces a network error', () async {
    final discovery = SsdpDiscovery(addresses: () async => []);
    await expectLater(
      discovery.search('service'),
      throwsA(isA<SocketException>()),
    );
  });
}
