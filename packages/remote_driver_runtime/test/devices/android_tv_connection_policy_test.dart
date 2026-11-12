import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/devices.dart';
import 'package:test/test.dart';

import 'driver_source_file.dart';

void main() {
  final policy = DeclarativeConnectionPolicy(
    DeviceCategory.television,
    DeviceRules.fromJson(driverSource('android-tv/remote-v2', 'device.json'))
        .policy!,
  );

  RemoteDevice saved({String host = '192.168.1.40', String peer = 'peer'}) =>
      RemoteDevice(
        id: 'android-tv-peer',
        name: 'Living room',
        providerId: 'android.tv',
        manufacturer: 'TCL',
        endpoints: [Uri.parse('tls://$host:6466')],
        metadata: {
          DeviceMetadataKeys.verifiedPeerIdentity: peer,
          DeviceMetadataKeys.macAddress: 'AA:BB:CC:DD:EE:FF',
          DeviceMetadataKeys.integrationId: 'android.tv.remote-v2',
        },
      );

  test('only network failures justify waking and retrying', () {
    for (final code in [
      'network',
      'networkAccess',
      'connectionRefused',
      'timeout',
    ]) {
      expect(
        policy.canRetryAfterWake(RemoteException(code, '')),
        isTrue,
        reason: code,
      );
    }
    for (final code in [
      'pairing',
      'pairingCode',
      'pairingTimeout',
      'certificate',
      'cancelled',
      'remote',
    ]) {
      expect(
        policy.canRetryAfterWake(RemoteException(code, '')),
        isFalse,
        reason: code,
      );
    }
  });

  test('a TV found at a new address keeps its saved identity', () {
    final discovered = RemoteDevice(
      id: 'android-tv-peer',
      name: '55C7K',
      providerId: 'android.tv',
      stableIdentity: true,
      endpoints: [Uri.parse('tls://192.168.1.77:6466')],
      metadata: const {
        'advertisedPeerIdentity': 'peer',
        DeviceMetadataKeys.correlationIdentity: 'aa:bb',
      },
    );
    final merged = policy.mergeDiscovered(saved(), discovered);
    expect(merged.id, 'android-tv-peer');
    expect(merged.name, 'Living room');
    expect(merged.endpoints, [Uri.parse('tls://192.168.1.77:6466')]);
    expect(merged.metadata, {
      'advertisedPeerIdentity': 'peer',
      DeviceMetadataKeys.correlationIdentity: 'aa:bb',
      ...saved().metadata,
    });
  });

  test('a different pinned TV is a different connection', () {
    expect(policy.sameConnection(saved(), saved()), isTrue);
    expect(policy.sameConnection(saved(), saved(peer: 'other')), isFalse);
  });
}
