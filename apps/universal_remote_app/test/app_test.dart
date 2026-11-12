import 'dart:async';

import 'support/start_nearby_search.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:universal_remote_app/data/devices/repositories/saved_device_repository.dart';
import 'package:universal_remote_app/data/pairing/repositories/secure_credential_store.dart';

import 'support/fake_provider.dart';

import 'support/integration_providers.dart';
import 'support/memory_storage.dart';
import 'support/fixture_protocols.dart';
import 'support/test_device.dart';

void main() {
  test(
    'protected credentials and profiles use separate storage keys',
    () async {
      final memory = MemoryStorage();
      final credentials = SecureCredentialStore(memory);
      final repository = SavedDeviceRepository(memory);
      await credentials.write(tv.id, 'secret');
      await repository.saveRegistered([const DeviceRegistry().fromProfile(tv)]);
      expect(memory.values['saved-devices.v2'], isNot(contains('secret')));
      expect(
        ((await repository.loadRegistered())
                .map((device) => device.preferredProfile.device)
                .toList())
            .single
            .id,
        tv.id,
      );
      await credentials.delete(tv.id);
      expect(await credentials.read(tv.id), isNull);
    },
  );
  test('bootstrap injects shared instances and persists settings and saved profiles', () async {
    final memory = MemoryStorage();
    final dependencies = await AppBootstrap.initialize(storage: memory);
    await dependencies.savedDevices.save(tv);
    await dependencies.savedDevices.rename(tv, 'Bedroom');
    await dependencies.settings.setTheme(ThemeMode.dark);
    await dependencies.dispose();
    final reloaded = await AppBootstrap.initialize(storage: memory);
    expect(reloaded.settings.theme.value, ThemeMode.dark);
    expect(reloaded.savedDevices.devices.value.single.name, 'Bedroom');
    await reloaded.savedDevices.forget(tv);
    expect(reloaded.savedDevices.devices.value, isEmpty);
    await reloaded.dispose();
  });
  test('active injected sessions release resources and concurrent dispose calls share completion', () async {
    final provider = FakeProvider();
    final dependencies = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..registerDefinition(provider.definition),
    );
    await dependencies.connection.connect(tv);
    final first = dependencies.dispose();
    final second = dependencies.dispose();
    expect(identical(first, second), isTrue);
    await first;
    expect(provider.last!.disposed, isTrue);
  });
  testWidgets(
    'supported typed capabilities enable controls and dispatch user actions',
    (tester) async {
      final provider = FakeProvider(enabledControls: true);
      final dependencies = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..registerDefinition(provider.definition),
      );
      await dependencies.savedDevices.save(tv);
      await tester.pumpWidget(UniversalRemoteApp(dependencies: dependencies));
      final navigation = find.byType(NavigationBar);
      final shell = tester.element(navigation);
      await tester.tap(find.text('Living room'));
      await tester.pumpAndSettle();
      final session = provider.last;
      expect(tester.element(navigation), same(shell));
      await tester.tap(find.text('Devices'));
      await tester.pumpAndSettle();
      expect(find.text('Living room'), findsOneWidget);
      expect(tester.element(navigation), same(shell));
      await tester.tap(find.text('Remote'));
      await tester.pumpAndSettle();
      expect(tester.element(navigation), same(shell));
      expect(provider.last, same(session));
      expect(
        tester
            .widget<ActionButton>(
              find
                  .ancestor(
                    of: find.byTooltip('OK'),
                    matching: find.byType(ActionButton),
                  )
                  .first,
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byTooltip('OK'));
      await tester.pumpAndSettle();
      expect(provider.last!.navigationControl.last, NavigationKey.enter);
      await tester.ensureVisible(find.byTooltip('Louder'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Louder'));
      await tester.pumpAndSettle();
      expect(provider.last!.volumeControl.level, 21);
      expect(dependencies.connection.volume.value!.volume, 21);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'discovery, selection and unsupported controls work with constructor injection',
    (tester) async {
      final provider = FakeProvider();
      final dependencies = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..registerDefinition(provider.definition),
        discoveryProtocols: fixtureProtocols([provider]),
        acquireNetwork: () async {},
        releaseNetwork: () async {},
      );
      await tester.pumpWidget(UniversalRemoteApp(dependencies: dependencies));
      await startNearbySearch(tester);
      await tester.pumpAndSettle();
      expect(find.text('Living room'), findsOneWidget);
      await tester.tap(find.text('Living room'));
      await tester.pump();
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('OK'), findsOneWidget);
      final ok = tester.widget<ActionButton>(
        find
            .ancestor(
              of: find.byTooltip('OK'),
              matching: find.byType(ActionButton),
            )
            .first,
      );
      expect(ok.onPressed, isNull); // No NavigationCapability was supplied.
      expect(dependencies.savedDevices.devices.value.single.id, tv.id);
      expect(find.byTooltip('Connected'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      // Let stream cancellation callbacks complete in their originating event loop.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(provider.last!.disposed, isTrue);
    },
  );
  testWidgets('pairing explains TV approval without displaying credentials', (
    tester,
  ) async {
    final provider = FakeProvider(pairing: true);
    final dependencies = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..registerDefinition(provider.definition),
    );
    await tester.pumpWidget(UniversalRemoteApp(dependencies: dependencies));
    unawaited(dependencies.connection.connect(tv));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Remote'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Approve the connection on your TV'), findsOneWidget);
    expect(find.text('secret'), findsNothing);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('Cancel connection'));
    await tester.tap(find.text('Cancel connection'));
    // Let stream cancellation callbacks complete in their originating event loop.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(
      dependencies.connection.state.value,
      DeviceConnectionState.disconnected,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  testWidgets(
    'connection errors are visible and saved devices remain selectable',
    (tester) async {
      final provider = FakeProvider(fail: true);
      final dependencies = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..registerDefinition(provider.definition),
      );
      await dependencies.savedDevices.save(tv);
      await tester.pumpWidget(UniversalRemoteApp(dependencies: dependencies));
      await tester.tap(find.text('Living room'));
      await tester.pumpAndSettle();
      expect(find.text('Test connection failed.'), findsOneWidget);
      expect(find.text('Retry connection'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('manual editor defaults to TLS and validates numeric addresses', (
    tester,
  ) async {
    final dependencies = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: integrationProviders(SecureCredentialStore(MemoryStorage())),
    );
    await tester.pumpWidget(UniversalRemoteApp(dependencies: dependencies));
    await tester.tap(find.byTooltip('Connect by IP'));
    await tester.pumpAndSettle();
    expect(find.text('Detect automatically'), findsOneWidget);
    await tester.tap(find.text('Detect automatically'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LG webOS').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced settings'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Legacy connection'),
          )
          .value,
      isFalse,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'TV IP address'),
      'invalid',
    );
    await tester.ensureVisible(find.text('Connect'));
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter the TV’s numeric local IP address.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
