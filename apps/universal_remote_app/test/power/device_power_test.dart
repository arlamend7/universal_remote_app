import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:remote_ui/remote_ui.dart';

import '../support/memory_storage.dart';
import '../support/capture_design.dart';
import '../support/fake_provider.dart';
import '../support/fake_wake_provider.dart';
import '../support/test_device.dart';

void main() {
  setUpAll(loadDesignFont);
  testWidgets(
    'power lives on remote, shutdown releases the session and wake retries until the TV connects',
    (tester) async {
      final provider = FakeWakeProvider(startupFailures: 1);
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..register(provider),
      );
      await app.savedDevices.save(tv);
      await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
      await tester.tap(find.text('Living room'));
      await tester.pumpAndSettle();
      final controlsPosition = tester.getTopLeft(
        find.byType(GridNavigationWidget).first,
      );
      app.connection.volume.value = const VolumeState(32, false);
      await tester.pump();
      expect(
        tester.getTopLeft(find.byType(GridNavigationWidget).first),
        controlsPosition,
      );
      await tester.tap(find.byTooltip('Remote options'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(PopupMenuItem<String>, 'Power off'),
        findsNothing,
      );
      expect(
        find.widgetWithText(PopupMenuItem<String>, 'Disconnect'),
        findsNothing,
      );
      expect(find.text('Preferences'), findsNothing);
      await tester.tap(find.text('Customize remote'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back to remote'));
      await tester.pumpAndSettle();
      final controller = provider.last!;
      await tester.tap(find.byTooltip('Power off'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Power off'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(controller.powerControl.shutdowns, 1);
      expect(controller.disposed, isTrue);
      expect(
        app.connection.disconnectReason.value,
        DisconnectReason.poweredOff,
      );
      expect(find.text('Device connection'), findsNothing);
      expect(
        find.text('Connect to the TV to adjust its volume.'),
        findsNothing,
      );
      await tester.tap(find.byTooltip('Turn on TV'));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 300));
      expect(app.connection.state.value, DeviceConnectionState.reconnecting);
      expect(find.text('Waiting for your TV to start…'), findsOneWidget);
      expect(provider.wakes, 1);
      expect(provider.startupFailures, 0);
      final startupAttempt = provider.last!;
      await tester.pump(app.connection.wakeRetryDelay);
      await tester.pumpAndSettle();
      expect(startupAttempt.disposed, isTrue);
      expect(provider.wakes, 1);
      expect(app.connection.state.value, DeviceConnectionState.connected);
      expect(find.text('Device connection'), findsNothing);
      final disconnecting = app.connection.disconnect();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await disconnecting;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'unreachable device gets one explanation per attempt and no false powered-off state',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final provider = FakeProvider(fail: true);
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..register(provider),
      );
      await app.savedDevices.save(tv);
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: UniversalRemoteApp(dependencies: app),
        ),
      );
      await tester.tap(find.text('Living room'));
      await tester.pumpAndSettle();
      expect(find.text('Device connection'), findsOneWidget);
      expect(find.text('Unreachable'), findsOneWidget);
      expect(find.text('Test connection failed.'), findsOneWidget);
      await captureDesign(tester, capture, '21-offline-explanation');
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      app.connection.revision.value++;
      await tester.pumpAndSettle();
      expect(find.text('Device connection'), findsNothing);
      expect(find.byTooltip('Unreachable'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('power confirmation cannot turn off a different selected TV', (
    tester,
  ) async {
    final provider = FakeWakeProvider();
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..register(provider),
    );
    await app.savedDevices.save(tv);
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.tap(find.text('Living room'));
    await tester.pumpAndSettle();
    final original = provider.last!;
    await tester.tap(find.byTooltip('Power off'));
    await tester.pumpAndSettle();
    final bedroom = RemoteDevice(
      id: 'bedroom',
      name: 'Bedroom',
      providerId: provider.id,
      endpoints: tv.endpoints,
    );
    await tester.runAsync(() => app.connection.connect(bedroom));
    await tester.pumpAndSettle();
    final replacement = provider.last!;
    await tester.tap(find.widgetWithText(FilledButton, 'Power off'));
    await tester.pumpAndSettle();
    expect(original.powerControl.shutdowns, 0);
    expect(replacement.powerControl.shutdowns, 0);
    expect(app.connection.state.value, DeviceConnectionState.connected);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  });
  testWidgets(
    'background suspension does not create an offline notification or lose selection',
    (tester) async {
      final provider = FakeProvider(enabledControls: true);
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..register(provider),
      );
      await app.savedDevices.save(tv);
      await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
      await tester.tap(find.text('Living room'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => app.connection.lifecycle(AppLifecycleState.hidden),
      );
      await tester.pumpAndSettle();
      expect(app.connection.selected.value?.id, tv.id);
      expect(find.text('Device connection'), findsNothing);
      await tester.runAsync(
        () => app.connection.lifecycle(AppLifecycleState.resumed),
      );
      await tester.pumpAndSettle();
      expect(app.connection.state.value, DeviceConnectionState.connected);
      expect(find.text('Device connection'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    },
  );
}
