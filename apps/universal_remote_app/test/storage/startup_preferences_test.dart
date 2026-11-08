import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/data/devices/repositories/saved_device_repository.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  test(
    'startup and ordinary preferences do not access protected credentials',
    () async {
      final preferences = MemoryStorage();
      final protected = MemoryStorage()
        ..values['client-key.${tv.id}'] = 'protected-client-key';
      final app = await AppBootstrap.initialize(
        storage: preferences,
        credentialStorage: protected,
      );
      expect(protected.reads, isEmpty);
      await app.savedDevices.save(tv);
      await app.settings.setTheme(ThemeMode.dark);
      expect(protected.reads, isEmpty);
      expect(
        preferences.values.values.join(),
        isNot(contains('protected-client-key')),
      );
      expect(
        await app.savedDevices.credentials.read(tv.id),
        'protected-client-key',
      );
      expect(protected.reads, ['client-key.${tv.id}']);
      await app.dispose();
    },
  );
  test(
    'older protected profiles migrate only after an explicit import',
    () async {
      final preferences = MemoryStorage();
      final protected = MemoryStorage()..values['settings.theme'] = 'dark';
      protected.values['client-key.${tv.id}'] = 'protected-client-key';
      await SavedDeviceRepository(protected).save([tv]);
      final app = await AppBootstrap.initialize(
        storage: preferences,
        credentialStorage: protected,
      );
      expect(app.savedDevices.devices.value, isEmpty);
      expect(protected.reads, isEmpty);
      await app.importLegacyPreferences!();
      await app.savedDevices.initialize();
      await app.settings.initialize();
      expect(app.savedDevices.devices.value.single.id, tv.id);
      expect(app.settings.theme.value, ThemeMode.dark);
      expect(protected.reads, isNot(contains('client-key.${tv.id}')));
      expect(protected.values['client-key.${tv.id}'], 'protected-client-key');
      expect(
        preferences.values.values.join(),
        isNot(contains('protected-client-key')),
      );
      await app.dispose();
    },
  );
  test(
    'legacy import preserves preferences already written by this version',
    () async {
      final preferences = MemoryStorage()..values['settings.theme'] = 'light';
      final protected = MemoryStorage()..values['settings.theme'] = 'dark';
      final app = await AppBootstrap.initialize(
        storage: preferences,
        credentialStorage: protected,
      );
      await app.importLegacyPreferences!();
      expect(preferences.values['settings.theme'], 'light');
      expect(protected.reads, isNot(contains('settings.theme')));
      await app.dispose();
    },
  );
  test(
    'invalid older profiles never replace the new startup preference record',
    () async {
      final preferences = MemoryStorage();
      final protected = MemoryStorage()
        ..values['saved-devices.v1'] = 'invalid JSON';
      final app = await AppBootstrap.initialize(
        storage: preferences,
        credentialStorage: protected,
      );
      await expectLater(
        app.importLegacyPreferences!(),
        throwsA(isA<Exception>()),
      );
      expect(preferences.values.containsKey('saved-devices.v1'), isFalse);
      expect(protected.values['saved-devices.v1'], 'invalid JSON');
      await app.dispose();
    },
  );
}
