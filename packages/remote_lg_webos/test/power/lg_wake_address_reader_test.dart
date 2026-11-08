import 'package:test/test.dart';
import 'package:remote_lg_webos/remote_lg_webos.dart';
import 'package:remote_lg_webos/src/capabilities/power/lg_wake_address_reader.dart';

import '../support/fake_transport.dart';

const _wifi = '0a:0b:00:12:ef:03';
const _wired = 'aa:bb:cc:dd:ee:ff';
const _host = '172.16.1.13';
const _service = 'ssap://com.webos.service.connectionmanager';

void main() {
  test(
    'selects the interface whose connected IP matches the TV endpoint',
    () async {
      final transport = FakeTransport();
      final client = SsapClient(transport);
      transport.respond = (request) =>
          transport.reply(request, switch (request['uri']) {
            '$_service/getinfo' => {
              'wifiInfo': {'macAddress': _wifi},
              'wiredInfo': {'macAddress': _wired},
            },
            _ => {
              'wifi': {
                'ipAddress': _host,
                'state': 'connected',
                'netmask': '255.255.255.0',
              },
              'wired': {'ipAddress': '172.16.1.15', 'state': 'connected'},
            },
          });
      final target = await LgWakeAddressReader(client).read(_host);
      expect(target?.macAddress, _wifi);
      expect(target?.broadcastAddress, '172.16.1.255');
      expect(transport.sent.map((item) => item['uri']), [
        '$_service/getinfo',
        '$_service/getStatus',
      ]);
      expect(await LgWakeAddressReader(client).read('172.16.1.99'), isNull);
      await client.close();
    },
  );
  test('matches a secondary Ethernet interface by name rather than its default MAC', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    transport.respond = (request) =>
        transport.reply(request, switch (request['uri']) {
          '$_service/getinfo' => {
            'wiredInfo': {
              'macAddress': _wired,
              'interfaces': [
                {'name': 'eth1', 'macAddress': _wifi},
              ],
            },
          },
          _ => {
            'wired': {
              'ipAddress': '172.16.1.15',
              'state': 'connected',
              'interfaceName': 'eth0',
              'interfaces': [
                {'name': 'eth1', 'ipAddress': _host, 'state': 'connected'},
              ],
            },
          },
        });
    expect((await LgWakeAddressReader(client).read(_host))?.macAddress, _wifi);
    await client.close();
  });
  test('supports the older status spelling only when the newer method is unsupported', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    transport.respond = (request) {
      if (request['uri'] == '$_service/getStatus') {
        transport.reject(request, '404 not found');
        return;
      }
      transport.reply(request, switch (request['uri']) {
        '$_service/getinfo' => {
          'wiredInfo': {'macAddress': _wired},
        },
        _ => {
          'wired': {'ipAddress': _host, 'state': 'connected'},
        },
      });
    };
    expect((await LgWakeAddressReader(client).read(_host))?.macAddress, _wired);
    expect(transport.sent.last['uri'], '$_service/getstatus');
    await client.close();
  });
  test(
    'permission rejection does not retry or close the connected session',
    () async {
      final transport = FakeTransport();
      final client = SsapClient(transport);
      transport.respond = (request) =>
          transport.reject(request, '403 permission denied');
      expect(await LgWakeAddressReader(client).read(_host), isNull);
      expect(transport.sent, hasLength(1));
      expect(client.isClosed, isFalse);
      await client.close();
    },
  );
}
