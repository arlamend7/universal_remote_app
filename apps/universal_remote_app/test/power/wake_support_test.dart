import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';

import '../support/memory_storage.dart';
import '../support/fake_provider.dart';
import '../support/integration_providers.dart';

import 'package:universal_remote_app/data/pairing/repositories/secure_credential_store.dart';

import '../support/test_device.dart';

void main() {
  test('paired Smart TV Pro can wake through its driver without a MAC', () {
    final registry = integrationProviders(
      SecureCredentialStore(MemoryStorage()),
    );
    final device = RemoteDevice(
      id: 'android-tv',
      name: 'Living room',
      providerId: 'android.tv',
      model: 'Smart TV Pro',
      endpoints: [Uri.parse('tls://192.168.1.20:6466')],
    );
    expect(registry.canWake(device), isFalse);
    expect(
      registry.canWake(
        copyDevice(
          device,
          metadata: {DeviceMetadataKeys.verifiedPeerIdentity: 'paired'},
        ),
      ),
      isTrue,
    );
  });

  test('wake needs integration support and a valid configured MAC, not metadata alone', () async {
    final fake = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()
        ..registerDefinition(FakeProvider().definition),
    );
    expect(
      fake.providers.canWake(
        copyDevice(tv, metadata: {'macAddress': 'AA:BB:CC:DD:EE:FF'}),
      ),
      isFalse,
    );
    await fake.dispose();
    final storage = MemoryStorage();
    final lg = await AppBootstrap.initialize(
      storage: storage,
      registry: integrationProviders(SecureCredentialStore(storage)),
    );
    final device = RemoteDevice(id: 'lg', name: 'LG', providerId: 'lg.webos');
    expect(lg.providers.canWake(device), isFalse);
    expect(
      lg.providers.canWake(
        copyDevice(device, metadata: {'macAddress': 'invalid'}),
      ),
      isFalse,
    );
    expect(
      lg.providers.canWake(
        copyDevice(device, metadata: {'macAddress': 'AA:BB:CC:DD:EE:FF'}),
      ),
      isTrue,
    );
    await lg.dispose();
  });
}
