import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/devices.dart';

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'driver_source_file.dart';
import 'fake_discovery_network.dart';

Map<String, Object?> _device(RemoteDevice? device, {bool random = false}) => {
  if (device != null) ...{
    'id': random ? '<profile>' : device.id,
    'name': device.name,
    'providerId': device.providerId,
    'manufacturer': device.manufacturer,
    'model': device.model,
    'category': device.category.name,
    'stableIdentity': device.stableIdentity,
    'endpoints': device.endpoints.map((uri) => '$uri').toList(),
    'metadata': device.metadata,
  },
};

DeclarativeIdentifier _identifier(
  String providerId,
  String integration,
  DiscoveryNetwork network,
) => DeclarativeIdentifier(
  providerId,
  DiscoveryRules.fromJson(driverSource(integration, 'discovery.json')),
  network,
);

DeclarativeManualSetup _setup(String providerId, String integration) =>
    DeclarativeManualSetup(
      providerId,
      DeviceRules.fromJson(driverSource(integration, 'device.json')).setup!,
    );

/// Outputs recorded from the retired manufacturer identifiers and providers.
final _golden = jsonDecode(
  File(
    Directory('test/devices/golden').existsSync()
        ? 'test/devices/golden/legacy_devices.json'
        : 'packages/remote_driver_runtime/test/devices/golden/legacy_devices.json',
  ).readAsStringSync(),
) as Map<String, Object?>;

Future<void> _same(
  ProviderIdentifier declarative,
  DiscoveryObservation observation, {
  bool random = false,
}) async {
  final token = DiscoveryCancellation();
  final actual = await declarative.identify(observation, token);
  final key =
      '${declarative.id} ${observation.serviceType} ${observation.endpoint} '
      '${observation.metadata} ${random ? 'random' : 'stable'}';
  expect(_golden.containsKey(key), isTrue, reason: key);
  expect(
    _device(actual?.profile.device, random: random),
    _golden[key],
    reason: key,
  );
}

DiscoveryObservation _ssdp(
  String service,
  String host,
  Map<String, String> metadata,
) => DiscoveryObservation(
  protocolId: DiscoveryProtocol.ssdp,
  serviceType: service,
  endpoint: Uri(scheme: 'http', host: host, port: 1900),
  metadata: metadata,
);

void main() {
  test('LG discovery matches the legacy identifier', () async {
    const service = 'urn:lge-com:service:webos-second-screen:1';
    final declarative = _identifier(
      'lg.webos',
      'lg-webos/webos-22-plus',
      FakeDiscoveryNetwork(),
    );
    expect(declarative.label, 'LG webOS');
    for (final observation in [
      _ssdp(service, '192.168.1.20', {
        'usn': 'uuid:abc-123::urn:x',
        'friendlyname': ' Living room ',
        'modelname': 'OLED55C2',
      }),
      _ssdp(service, '192.168.1.20', {'usn': 'uuid:abc'}),
      _ssdp(service, '192.168.1.20', {'usn': 'notuuid'}),
      _ssdp('urn:other', '192.168.1.20', {'usn': 'uuid:abc'}),
    ]) {
      await _same(declarative, observation);
    }
  });

  test('Samsung discovery matches the legacy identifier', () async {
    const service = 'urn:samsung.com:service:MultiScreenService:1';
    final declarative = _identifier(
      'samsung.tizen',
      'samsung-tizen/tizen-supported',
      FakeDiscoveryNetwork(),
    );
    for (final observation in [
      _ssdp(service, '192.168.1.42', {
        'usn': 'uuid:0EE3A7F0-1234-5678-9ABC-DEF012345678::x',
        'st': service,
        'friendlyname': 'Samsung',
        'modelname': 'QN65',
      }),
      _ssdp(service, '192.168.1.42', {
        'usn': 'uuid:0ee3a7f0-1234-5678',
        'st': 'x',
      }),
      _ssdp(service, '8.8.8.8', {
        'usn': 'uuid:0ee3a7f0-1234-5678-9abc',
        'st': service,
      }),
    ]) {
      await _same(declarative, observation);
    }
  });

  test('Roku discovery matches the legacy identifier', () async {
    final declarative = _identifier(
      'roku.ecp',
      'roku-ecp/roku-supported',
      FakeDiscoveryNetwork(),
    );
    for (final observation in [
      _ssdp('roku:ecp', '192.168.1.30', {
        'usn': 'uuid:roku:ecp:YN00AB123456',
        'st': 'roku:ecp',
        'location': 'http://192.168.1.30:8060/',
      }),
      _ssdp('roku:ecp', '192.168.1.30', {
        'usn': 'uuid:roku:ecp:YN00AB123456',
        'st': 'roku:ecp',
        'location': 'http://192.168.1.99:8060/',
      }),
      _ssdp('roku:ecp', '8.8.4.4', {
        'usn': 'uuid:roku:ecp:YN00',
        'st': 'roku:ecp',
        'location': 'http://8.8.4.4:8060/',
      }),
    ]) {
      await _same(declarative, observation);
    }
  });

  test('Android TV discovery matches the legacy identifier', () async {
    for (final peer in ['AB:CD', null]) {
      final declarative = _identifier(
        'android.tv',
        'android-tv/remote-v2',
        FakeDiscoveryNetwork(peer: peer),
      );
      for (final port in [6466, 6467]) {
        await _same(
          declarative,
          DiscoveryObservation(
            protocolId: DiscoveryProtocol.bonjour,
            serviceType: '_androidtvremote2._tcp',
            endpoint: Uri(scheme: 'tcp', host: '192.168.1.50', port: port),
            metadata: const {'name': 'Bedroom TV'},
          ),
          random: peer == null,
        );
      }
    }
  });

  group('manual setup matches the legacy providers', () {
    final cases = <String, ManualDeviceProvider>{
      'lg': _setup('lg.webos', 'lg-webos/webos-22-plus'),
      'samsung': _setup('samsung.tizen', 'samsung-tizen/tizen-supported'),
      'android': _setup('android.tv', 'android-tv/remote-v2'),
      'roku': _setup('roku.ecp', 'roku-ecp/roku-supported'),
    };
    const labels = {
      'lg': ('LG webOS', true),
      'samsung': ('Samsung Tizen', true),
      'android': ('Google TV / Android TV', false),
      'roku': ('Roku (local HTTP)', false),
    };
    for (final MapEntry(key: name, value: declarative) in cases.entries) {
      test(name, () {
        expect(declarative.manualSetupLabel, labels[name]!.$1);
        expect(declarative.showsAdvancedSetup, labels[name]!.$2);
        final variants = [
          (address: '192.168.1.20', legacy: false, pointer: false, mac: ''),
          (address: '192.168.1.20', legacy: true, pointer: false, mac: ''),
          (address: '192.168.1.20', legacy: false, pointer: true, mac: ''),
          (
            address: '192.168.1.20',
            legacy: false,
            pointer: false,
            mac: 'aa-bb-cc-dd-ee-ff',
          ),
          (address: 'not an ip', legacy: false, pointer: false, mac: ''),
        ];
        for (final variant in variants) {
          Object? outcome() {
            try {
              final device = declarative.manualDeviceFactory(
                address: variant.address,
                name: 'Den',
                legacy: variant.legacy,
                allowInsecurePointer: variant.pointer,
                certificate: declarative.showsAdvancedSetup ? 'AQID' : null,
                mac: variant.mac,
              );
              return _device(device, random: true)
                ..['id'] = device.id.replaceAll(
                  RegExp(r'[A-Za-z0-9_-]{24}$'),
                  '*',
                );
            } on Object {
              return 'rejected';
            }
          }

          expect(
            outcome(),
            _golden['setup $name $variant'],
            reason: '$variant',
          );
        }
      });
    }
  });
}
