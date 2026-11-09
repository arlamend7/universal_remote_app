import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';

import '../support/memory_storage.dart';

void main() {
  test('verified rediscovery can update a manual profile and retain trust, credentials, layout and order as addresses change', () async {
    final app = await AppBootstrap.initialize(storage: MemoryStorage());
    final manual = RemoteDevice(
      id: 'profile',
      name: 'My TV',
      providerId: 'lg.webos',
      stableIdentity: false,
      endpoints: [Uri.parse('wss://192.168.1.2:3001')],
      metadata: {
        'trustedCertificateDer': 'pinned',
        'verifiedPeerIdentity': 'verified-tv',
        'remoteLayout.v1': 'layout',
      },
    );
    final other = RemoteDevice(
      id: 'second',
      name: 'Other',
      providerId: 'lg.webos',
    );
    await app.savedDevices.save(manual);
    await app.savedDevices.save(other);
    await app.savedDevices.credentials.write(manual.id, 'protected-test-key');
    final profiles = DiscoveryProfiles(
      profiles: () => app.savedDevices.devices.value,
      update: app.savedDevices.updateExisting,
    );
    final discovered = RemoteDevice(
      id: 'uuid:one',
      name: 'Advertised name',
      providerId: 'lg.webos',
      endpoints: [Uri.parse('wss://192.168.1.2:3001')],
      metadata: {'advertisedPeerIdentity': 'verified-tv'},
    );
    final changed = RemoteDevice(
      id: discovered.id,
      name: discovered.name,
      providerId: discovered.providerId,
      endpoints: [Uri.parse('ws://192.168.1.9:3000')],
      metadata: discovered.metadata,
    );
    expect(profiles.registered(changed)?.id, manual.id);
    // Discovery itself never changes transport, address or certificate trust.
    expect(
      app.savedDevices.devices.value.first.endpoints.first.host,
      '192.168.1.2',
    );
    await profiles.updateAddress(changed);
    final updated = app.savedDevices.devices.value.first;
    expect(updated.id, manual.id);
    expect(updated.name, 'My TV');
    expect(updated.endpoints.single.toString(), 'wss://192.168.1.9:3001');
    expect(updated.metadata['trustedCertificateDer'], 'pinned');
    expect(updated.metadata['remoteLayout.v1'], 'layout');
    expect(
      await app.savedDevices.credentials.read(manual.id),
      'protected-test-key',
    );
    expect(app.savedDevices.devices.value.last.id, other.id);
    await app.dispose();
  });
}
