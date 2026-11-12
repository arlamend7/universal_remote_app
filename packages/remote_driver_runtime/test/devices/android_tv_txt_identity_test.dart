import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/devices.dart';
import 'package:test/test.dart';

import 'driver_source_file.dart';
import 'fake_discovery_network.dart';

DeclarativeIdentifier _identifier(
  String providerId,
  String integration, {
  String? peer,
  String? serial,
}) => DeclarativeIdentifier(
  providerId,
  DiscoveryRules.fromJson(driverSource(integration, 'discovery.json')),
  FakeDiscoveryNetwork(peer: peer, serial: serial),
);

/// Documented advertisement shapes (Android TV Remote Service mDNS with the
/// `bt` TXT key; Roku ECP SSDP). Not captures from specific TVs.
DiscoveryObservation _androidTv({Map<String, String> txt = const {}}) =>
    DiscoveryObservation(
      protocolId: DiscoveryProtocol.bonjour,
      serviceType: '_androidtvremote2._tcp',
      endpoint: Uri(scheme: 'tcp', host: '192.168.1.60', port: 6466),
      metadata: {...txt, 'name': '55C7K'},
    );

DiscoveryObservation get _tclRokuTv => DiscoveryObservation(
  protocolId: DiscoveryProtocol.ssdp,
  serviceType: 'roku:ecp',
  endpoint: Uri(scheme: 'http', host: '192.168.1.61', port: 8060),
  metadata: const {
    'st': 'roku:ecp',
    'usn': 'uuid:roku:ecp:x00000abcdef',
    'location': 'http://192.168.1.61:8060/',
  },
);

Future<RemoteDevice?> _identify(
  DeclarativeIdentifier identifier,
  DiscoveryObservation observation,
) async => (await identifier.identify(
  observation,
  DiscoveryCancellation(),
))?.profile.device;

void main() {
  test('the advertised bt value becomes correlation evidence only', () async {
    final device = (await _identify(
      _identifier('android.tv', 'android-tv/remote-v2', peer: 'peer-a'),
      _androidTv(txt: {'txt.bt': 'AA:BB:CC:DD:EE:FF'}),
    ))!;
    expect(device.id, 'android-tv-peer-a');
    expect(device.stableIdentity, isTrue);
    expect(device.metadata, {
      'advertisedPeerIdentity': 'peer-a',
      DeviceMetadataKeys.correlationIdentity: 'AA:BB:CC:DD:EE:FF',
    });
    expect(device.metadata.containsKey(DeviceMetadataKeys.macAddress), isFalse);
  });

  test('without TXT data the identity is unchanged', () async {
    final device = (await _identify(
      _identifier('android.tv', 'android-tv/remote-v2', peer: 'peer-a'),
      _androidTv(),
    ))!;
    expect(device.id, 'android-tv-peer-a');
    expect(device.metadata, {'advertisedPeerIdentity': 'peer-a'});
  });

  test('sightings whose 6467 probe failed merge through bt', () async {
    final identifier = _identifier('android.tv', 'android-tv/remote-v2');
    final observation = _androidTv(txt: {'txt.bt': 'aa:bb:cc:dd:ee:ff'});
    final first = (await _identify(identifier, observation))!;
    final second = (await _identify(identifier, observation))!;
    expect(first.stableIdentity, isFalse);
    expect(first.id, isNot(second.id));
    expect(const DeviceIdentifierResolver().same(first, second), isTrue);
  });

  test('a TCL Roku TV matches Roku ECP, never Android TV', () async {
    expect(
      await _identify(
        _identifier('android.tv', 'android-tv/remote-v2', peer: 'peer-a'),
        _tclRokuTv,
      ),
      isNull,
    );
    final roku = await _identify(
      _identifier('roku.ecp', 'roku-ecp/roku-supported'),
      _tclRokuTv,
    );
    expect(roku?.providerId, 'roku.ecp');
  });

  test('other Bonjour services are never matched as Android TV', () async {
    final identifier = _identifier(
      'android.tv',
      'android-tv/remote-v2',
      peer: 'peer-a',
    );
    for (final service in ['_androidtvremote._tcp', '_googlecast._tcp']) {
      final device = await _identify(
        identifier,
        DiscoveryObservation(
          protocolId: DiscoveryProtocol.bonjour,
          serviceType: service,
          endpoint: Uri(scheme: 'tcp', host: '192.168.1.62', port: 6466),
        ),
      );
      expect(device, isNull, reason: service);
    }
  });
}
