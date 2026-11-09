import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/data/devices/mappers/saved_device_mapper.dart';
import 'package:universal_remote_app/data/devices/repositories/saved_device_repository.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  test('startup ignores all V1 device data and leaves it untouched', () async {
    final legacy = jsonEncode([const SavedDeviceMapper().toJson(tv)]);
    final preferences = MemoryStorage()
      ..values['saved-devices.v1'] = legacy
      ..values['dashboards.v1'] = '{}';
    final protected = MemoryStorage()
      ..values['client-key.${tv.id}'] = 'old-key';
    final app = await AppBootstrap.initialize(
      storage: preferences,
      credentialStorage: protected,
    );

    expect(app.savedDevices.devices.value, isEmpty);
    expect(preferences.reads, isNot(contains('saved-devices.v1')));
    expect(preferences.reads, isNot(contains('dashboards.v1')));
    expect(preferences.values[SavedDeviceRepository.currentKey], isNull);
    expect(preferences.values['saved-devices.v1'], legacy);
    expect(preferences.values['dashboards.v1'], '{}');
    expect(await app.savedDevices.credentials.read(tv.id), isNull);
    expect(protected.reads, isNot(contains('client-key.${tv.id}')));
    expect(protected.values['client-key.${tv.id}'], 'old-key');
    await app.dispose();
  });

  test('corrupt V2 is reported without overwriting its bytes', () async {
    final storage = MemoryStorage();
    storage.values['saved-devices.v1'] = jsonEncode([
      const SavedDeviceMapper().toJson(tv),
    ]);
    storage.values[SavedDeviceRepository.currentKey] = 'broken';
    await expectLater(
      SavedDeviceRepository(storage).loadRegistered(),
      throwsA(isA<RemoteException>()),
    );
    expect(storage.values[SavedDeviceRepository.currentKey], 'broken');
  });

  test(
    'linking, selecting and unlinking preserve independent authorization',
    () async {
      final preferences = MemoryStorage();
      final protected = MemoryStorage();
      final app = await AppBootstrap.initialize(
        storage: preferences,
        credentialStorage: protected,
      );
      final secondary = RemoteDevice(
        id: 'secondary',
        name: 'Bedroom',
        providerId: 'android.tv',
        category: DeviceCategory.television,
        endpoints: tv.endpoints,
      );
      await app.savedDevices.save(tv);
      await app.savedDevices.save(secondary);
      await app.savedDevices.credentials.write(tv.id, 'first-key');
      await app.savedDevices.credentials.write(secondary.id, 'second-key');
      await app.savedDevices.associate(tv.id, secondary.id);
      await app.savedDevices.preferProvider(tv.id, secondary.providerId);
      expect(app.savedDevices.devices.value.single.id, secondary.id);
      expect(app.savedDevices.logicalDevice(secondary.id)!.id, tv.id);
      await app.savedDevices.detach(tv.id, secondary.id);
      expect(app.savedDevices.devices.value, hasLength(2));
      expect(await app.savedDevices.credentials.read(tv.id), 'first-key');
      expect(
        await app.savedDevices.credentials.read(secondary.id),
        'second-key',
      );
      await app.savedDevices.associate(tv.id, secondary.id);
      await app.savedDevices.forget(tv);
      expect(await app.savedDevices.credentials.read(tv.id), isNull);
      expect(await app.savedDevices.credentials.read(secondary.id), isNull);
      await app.dispose();
    },
  );
}
