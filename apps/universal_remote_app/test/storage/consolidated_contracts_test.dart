import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/data/dashboards/repositories/local_dashboard_repository.dart';
import 'package:universal_remote_app/data/devices/repositories/saved_device_repository.dart';
import 'package:universal_remote_app/data/pairing/repositories/secure_credential_store.dart';

import '../support/memory_storage.dart';

void main() {
  test('existing device, dashboard and credential identifiers survive consolidation', () async {
    final preferences = MemoryStorage()
      ..values['saved-devices.v2'] = _savedDevice
      ..values['dashboards.v2'] = jsonEncode({'tv-profile': _savedDashboard});
    final protected = MemoryStorage()
      ..values['client-key.v2.tv-profile'] = 'fixture-credential';
    final repository = SavedDeviceRepository(preferences);
    final dashboardRepository = LocalDashboardRepository(preferences);
    final credentials = SecureCredentialStore(protected);

    final devices = await repository.loadRegistered();
    final registered = devices.single;
    final device = registered.preferredProfile.device;
    expect(device.id, 'tv-profile');
    expect(device.providerId, 'lg.webos');
    expect(device.category, DeviceCategory.television);
    expect(device.pairingState, PairingState.paired);
    expect(device.capabilities, {RemoteCapability.navigation});
    expect(
      device.metadata[DeviceMetadataKeys.integrationId],
      'lg.webos.22-plus',
    );
    expect(device.metadata[DeviceMetadataKeys.trustedCertificateDer], 'AQID');
    expect(await credentials.read(device.id), 'fixture-credential');

    final saved = await dashboardRepository.load();
    final layout = GridLayout.decode(saved[device.id]!);
    expect(layout.items.map((item) => item.definitionId), [
      'home',
      'future.control',
    ]);
    final home = layout.items.first;
    expect(home.elementStyles.keys, contains('nav_home'));

    await repository.saveRegistered(devices);
    await dashboardRepository.save({device.id: layout.encode()});
    final restored =
        (await repository.loadRegistered()).single.preferredProfile.device;
    expect(restored.metadata, device.metadata);
    expect(
      GridLayout.decode((await dashboardRepository.load())[device.id]!)
          .encode(),
      layout.encode(),
    );
    expect(protected.values.keys, ['client-key.v2.tv-profile']);
  });
}

const _savedDevice = '''
{
  "version": 2,
  "devices": [{
    "id": "tv-profile",
    "name": "Living room",
    "category": "television",
    "preferredProviderId": "lg.webos",
    "profiles": [{
      "confirmed": true,
      "configuration": {
        "id": "tv-profile",
        "name": "Living room",
        "providerId": "lg.webos",
        "category": "television",
        "capabilities": ["navigation"],
        "stableIdentity": true,
        "pairingState": "paired",
        "endpoints": ["wss://192.168.1.10:3001"],
        "metadata": {
          "driverIntegrationId": "lg.webos.22-plus",
          "trustedCertificateDer": "AQID"
        }
      }
    }]
  }]
}
''';

const _savedDashboard = '''
{
  "version": 2,
  "items": [
    {
      "id": "home-shortcut",
      "kind": "home",
      "x": 0, "y": 0, "w": 1, "h": 1,
      "elements": {"nav_home": {"showLabel": false}}
    },
    {
      "id": "future",
      "definitionId": "future.control",
      "x": 1, "y": 0, "w": 1, "h": 1
    }
  ]
}
''';
