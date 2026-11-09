import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';

RemoteDevice found(
  String id,
  String ip, {
  String? uuid,
  bool stable = true,
  String provider = 'lg.webos',
}) => RemoteDevice(
  id: id,
  name: 'TV',
  providerId: provider,
  stableIdentity: stable,
  endpoints: [Uri.parse('wss://$ip:3001')],
  metadata: {if (uuid != null) 'usn': 'uuid:$uuid::second-screen'},
);

void main() {
  const resolver = DeviceIdentifierResolver();
  test('unverified UUIDs cannot match across addresses or providers', () {
    final saved = found('a', '192.168.1.2', uuid: 'tv-one');
    final changed = found('b', '192.168.1.8', uuid: 'tv-one');
    final otherMechanism = found(
      'c',
      '192.168.1.9',
      uuid: 'tv-one',
      provider: 'other',
    );
    expect(resolver.same(saved, changed), isFalse);
    expect(resolver.same(saved, otherMechanism), isFalse);
  });
  test('manual profiles require stronger evidence than a shared address', () {
    final manual = found('profile', '192.168.1.2', stable: false);
    final discovered = found('discovered', '192.168.1.2', uuid: 'tv-one');
    expect(resolver.same(manual, discovered), isFalse);
    final replaced = found('other', '192.168.1.2', uuid: 'tv-two');
    expect(resolver.same(discovered, replaced), isFalse);
    expect(resolver.same(manual, found('new', '192.168.1.8')), isFalse);
  });
}
