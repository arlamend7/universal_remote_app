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
  test(
    'UUID matches changing addresses, interfaces and discovery mechanisms',
    () {
      final saved = found('a', '192.168.1.2', uuid: 'tv-one');
      final changed = found('b', '192.168.1.8', uuid: 'tv-one');
      final otherMechanism = found(
        'c',
        '192.168.1.9',
        uuid: 'tv-one',
        provider: 'other',
      );
      expect(DeviceIdentity.same(saved, changed), isTrue);
      expect(
        DeviceIdentity.unique([saved, changed, otherMechanism]),
        hasLength(1),
      );
    },
  );
  test(
    'manual profiles use address fallback but never merge conflicting UUIDs',
    () {
      final manual = found('profile', '192.168.1.2', stable: false);
      final discovered = found('discovered', '192.168.1.2', uuid: 'tv-one');
      expect(DeviceIdentity.same(manual, discovered), isTrue);
      final replaced = found('other', '192.168.1.2', uuid: 'tv-two');
      expect(DeviceIdentity.same(discovered, replaced), isFalse);
      expect(DeviceIdentity.same(manual, found('new', '192.168.1.8')), isFalse);
    },
  );
}
