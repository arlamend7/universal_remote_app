import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/data/storage/adapters/native_preferences_storage.dart';
import 'package:universal_remote_app/domains/diagnostics/services/diagnostic_logger.dart';
import 'package:universal_remote_app/domains/settings/services/settings_controller.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native preferences allow startup and both new settings', () async {
    const channel = MethodChannel('test/preferences');
    final values = <String, String>{
      'settings.autoReconnect': 'false',
      'settings.screenAwake': 'true',
    };
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      final key = call.arguments['key'] as String;
      if (call.method == 'write') {
        values[key] = call.arguments['value'] as String;
      }
      return call.method == 'read' ? values[key] : null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final awake = <bool>[];
    final storage = NativePreferencesStorage(channel: channel);
    final app = await AppBootstrap.initialize(storage: storage);
    expect(app.settings.autoReconnect.value, isFalse);
    expect(app.settings.welcomeCompleted.value, isFalse);
    await app.settings.completeWelcome();
    await app.dispose();

    final settings = SettingsController(
      storage,
      DiagnosticLogger(),
      applyScreenAwake: (value) async => awake.add(value),
    );
    await settings.initialize();
    expect(awake, [true]);
    expect(settings.welcomeCompleted.value, isTrue);
    await settings.setScreenAwake(false);
    await settings.setAutoReconnect(true);
    expect(awake, [true, false]);
    expect(values['settings.screenAwake'], 'false');
    expect(values['settings.autoReconnect'], 'true');
    settings.dispose();
  });

  test(
    'startup and ordinary preferences do not access protected credentials',
    () async {
      final preferences = MemoryStorage();
      final protected = MemoryStorage()
        ..values['client-key.v2.${tv.id}'] = 'protected-client-key';
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
      expect(protected.reads, ['client-key.v2.${tv.id}']);
      await app.dispose();
    },
  );
}
