import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';
import 'package:remote_roku/remote_roku.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Roku discovery uses serial identity and rejects foreign locations',
    () async {
      Future<RemoteDevice> discover(String host) async {
        final address = InternetAddress(host);
        final provider = RokuProvider(
          discovery: SsdpDiscovery(
            addresses: () async => [address],
            searchRoute: (service, _, _, _) async {
              expect(service, 'roku:ecp');
              return [
                SsdpAdvertisement(address, {
                  'st': service,
                  'usn': 'uuid:roku:ecp:TEST01',
                  'location': 'http://$host:8060/',
                }),
                SsdpAdvertisement(address, {
                  'st': service,
                  'usn': 'uuid:roku:ecp:spoof',
                  'location': 'http://192.168.1.99:8060/',
                }),
              ];
            },
          ),
        );
        return (await provider.discover(DiscoveryCancellation())).single;
      }

      final previous = await discover('192.168.1.10');
      final moved = await discover('192.168.1.11');
      expect(moved.id, previous.id);
      expect(moved.endpoints.single.host, '192.168.1.11');
    },
  );
}
