import 'package:remote_android_tv/src/android_tv_provider.dart';
import 'package:remote_core/remote_core.dart';
import 'package:test/test.dart';

import 'support/memory_credentials.dart';

void main() {
  final provider = AndroidTvProvider(credentials: MemoryCredentials());
  RemoteDevice device({Map<String, String> metadata = const {}}) =>
      RemoteDevice(
        id: 'tv',
        name: 'TV',
        providerId: provider.id,
        endpoints: [Uri(scheme: 'tls', host: '192.168.1.30', port: 6466)],
        metadata: metadata,
      );

  test('wake needs the TV MAC address, which is learned after connecting', () {
    expect(provider.canWakeDevice(device()), isFalse);
    expect(
      provider.canWakeDevice(device(metadata: {'macAddress': 'not a mac'})),
      isFalse,
    );
    expect(
      provider.canWakeDevice(
        device(metadata: {'macAddress': 'AA:BB:CC:DD:EE:FF'}),
      ),
      isTrue,
    );
  });

  test('waking without a known MAC explains how to learn it', () async {
    await expectLater(
      provider.wakeDevice(device()),
      throwsA(
        isA<RemoteException>().having(
          (error) => error.code,
          'code',
          'wakeUnavailable',
        ),
      ),
    );
  });
}
