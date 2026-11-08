import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';

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
}
