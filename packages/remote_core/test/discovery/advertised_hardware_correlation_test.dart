import 'package:remote_core/remote_core.dart';
import 'package:test/test.dart';

RemoteDevice _sighting(
  String id, {
  String address = '192.168.1.40',
  String provider = 'android.tv',
  String? peer,
  String? hardware,
  bool stable = false,
}) => RemoteDevice(
  id: id,
  name: 'Living Room TV',
  providerId: provider,
  stableIdentity: stable,
  endpoints: [Uri.parse('tls://$address:6466')],
  metadata: {
    if (peer != null) 'advertisedPeerIdentity': peer,
    if (hardware != null) DeviceMetadataKeys.correlationIdentity: hardware,
  },
);

ProviderMatch _match(RemoteDevice device) => ProviderMatch(
  ConnectionProfile(device, confirmed: true),
  DiscoveryObservation(
    protocolId: DiscoveryProtocol.bonjour,
    serviceType: '_androidtvremote2._tcp',
  ),
);

void main() {
  const resolver = DeviceIdentifierResolver();

  test('a sighting without a peer identity joins the same TV by its '
      'advertised hardware identifier at the same endpoint', () {
    final stable = _sighting(
      'android-tv-peer',
      peer: 'peer',
      hardware: 'aa:bb:cc:dd:ee:ff',
      stable: true,
    );
    final provisional = _sighting('random', hardware: 'AA:BB:CC:DD:EE:FF');
    expect(resolver.same(stable, provisional), isTrue);
    expect(resolver.same(provisional, stable), isTrue);
  });

  test('the identifier alone, the address alone or another provider '
      'never correlate', () {
    final tv = _sighting('one', hardware: 'aa');
    expect(
      resolver.same(
        tv,
        _sighting('two', address: '192.168.1.41', hardware: 'aa'),
      ),
      isFalse,
    );
    expect(resolver.same(tv, _sighting('two')), isFalse);
    expect(resolver.same(tv, _sighting('two', hardware: 'bb')), isFalse);
    expect(
      resolver.same(tv, _sighting('two', provider: 'lg.webos', hardware: 'aa')),
      isFalse,
    );
  });

  test('different peer identities win over an equal hardware identifier', () {
    expect(
      resolver.same(
        _sighting('one', peer: 'peer-1', hardware: 'aa'),
        _sighting('two', peer: 'peer-2', hardware: 'aa'),
      ),
      isFalse,
    );
  });

  test('a provisional sighting never replaces the stable identity', () {
    final stable = _match(
      _sighting('android-tv-peer', peer: 'peer', hardware: 'aa', stable: true),
    );
    final matches = [stable];
    resolver.add(matches, _match(_sighting('random', hardware: 'aa')));
    expect(matches.single, same(stable));
    final refreshed = _match(
      _sighting('android-tv-peer', peer: 'peer', hardware: 'aa', stable: true),
    );
    resolver.add(matches, refreshed);
    expect(matches.single, same(refreshed));
  });
}
