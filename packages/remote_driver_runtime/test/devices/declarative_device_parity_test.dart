import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/devices.dart';
import 'package:remote_driver_runtime/src/adapters/android_tv/android_tv_provider.dart';
import 'package:remote_driver_runtime/src/adapters/android_tv/discovery/android_tv_identifier.dart';
import 'package:remote_driver_runtime/src/adapters/roku/roku_identifier.dart';
import 'package:remote_driver_runtime/src/adapters/roku/roku_provider.dart';
import 'package:remote_driver_runtime/src/adapters/samsung_tizen/discovery/samsung_identifier.dart';
import 'package:remote_driver_runtime/src/adapters/samsung_tizen/samsung_provider.dart';
import 'package:remote_driver_runtime/tv_provider_adapters.dart';
import 'package:test/test.dart';

import '../adapters/lg_webos/support/memory_credentials.dart';
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

Future<void> _same(
  ProviderIdentifier legacy,
  ProviderIdentifier declarative,
  DiscoveryObservation observation, {
  bool random = false,
}) async {
  final token = DiscoveryCancellation();
  final expected = await legacy.identify(observation, token);
  final actual = await declarative.identify(observation, token);
  expect(
    _device(actual?.profile.device, random: random),
    _device(expected?.profile.device, random: random),
    reason: '${observation.serviceType} ${observation.metadata}',
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
      await _same(const LgIdentifier(), declarative, observation);
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
      await _same(const SamsungIdentifier(), declarative, observation);
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
      await _same(const RokuIdentifier(), declarative, observation);
    }
  });

  test('Android TV discovery matches the legacy identifier', () async {
    for (final peer in ['AB:CD', null]) {
      final declarative = _identifier(
        'android.tv',
        'android-tv/remote-v2',
        FakeDiscoveryNetwork(peer: peer),
      );
      final legacy = AndroidTvIdentifier(inspectIdentity: (_) async => peer);
      for (final port in [6466, 6467]) {
        await _same(
          legacy,
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
    final credentials = MemoryCredentials();
    final cases = <String, (ManualDeviceProvider, ManualDeviceProvider)>{
      'lg': (
        LgWebOsProvider(credentials: credentials),
        _setup('lg.webos', 'lg-webos/webos-22-plus'),
      ),
      'samsung': (
        SamsungProvider(credentials: credentials),
        _setup('samsung.tizen', 'samsung-tizen/tizen-supported'),
      ),
      'android': (
        AndroidTvProvider(credentials: credentials),
        _setup('android.tv', 'android-tv/remote-v2'),
      ),
      'roku': (
        const RokuProvider(),
        _setup('roku.ecp', 'roku-ecp/roku-supported'),
      ),
    };
    for (final MapEntry(key: name, value: (legacy, declarative))
        in cases.entries) {
      test(name, () {
        expect(declarative.manualSetupLabel, legacy.manualSetupLabel);
        expect(declarative.showsAdvancedSetup, legacy.showsAdvancedSetup);
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
          RemoteDevice? create(ManualDeviceProvider provider) =>
              provider.manualDeviceFactory(
                address: variant.address,
                name: 'Den',
                legacy: variant.legacy,
                allowInsecurePointer: variant.pointer,
                certificate: provider.showsAdvancedSetup ? 'AQID' : null,
                mac: variant.mac,
              );
          Object? outcome(ManualDeviceProvider provider) {
            try {
              final device = create(provider)!;
              return _device(device, random: true)
                ..['id'] = device.id.replaceAll(
                  RegExp(r'[A-Za-z0-9_-]{24}$'),
                  '*',
                );
            } on Object {
              return 'rejected';
            }
          }

          expect(outcome(declarative), outcome(legacy), reason: '$variant');
        }
      });
    }
  });
}
