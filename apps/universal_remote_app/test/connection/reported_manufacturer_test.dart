import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';

import '../support/fake_provider.dart';
import '../support/memory_storage.dart';
import '../support/test_device.dart';

RemoteDevice _unidentified(String? manufacturer) => RemoteDevice(
  id: tv.id,
  name: tv.name,
  providerId: tv.providerId,
  manufacturer: manufacturer,
  category: tv.category,
  endpoints: tv.endpoints,
);

void main() {
  test('a manufacturer reported by the session is saved', () async {
    final provider = FakeProvider(reportedManufacturer: 'TCL');
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..registerDefinition(provider.definition),
    );
    final device = _unidentified(null);
    await app.savedDevices.save(device);
    await app.connection.connect(device);
    expect(app.connection.state.value, DeviceConnectionState.connected);
    final saved = app.savedDevices.byId(tv.id)!;
    expect(saved.manufacturer, 'TCL');
    expect(saved.id, tv.id);
    await app.dispose();
  });

  test('a manufacturer already saved is not replaced', () async {
    final provider = FakeProvider(reportedManufacturer: 'TCL');
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..registerDefinition(provider.definition),
    );
    final known = _unidentified('Philips');
    await app.savedDevices.save(known);
    await app.connection.connect(known);
    expect(app.savedDevices.byId(tv.id)!.manufacturer, 'Philips');
    await app.dispose();
  });
}
