import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';

import '../support/fake_wake_provider.dart';
import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  testWidgets('IP sheet aligns its title, fields and equal-width actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await AppBootstrap.initialize(storage: MemoryStorage());
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.tap(find.byTooltip('Connect by IP'));
    await tester.pumpAndSettle();

    final title = tester.getRect(find.text('Connect by IP'));
    final platform = tester.getRect(
      find.byType(DropdownButtonFormField<String>),
    );
    final name = tester.getRect(find.byType(TextField).first);
    final cancel = tester.getRect(
      find.widgetWithText(OutlinedButton, 'Cancel'),
    );
    final connect = tester.getRect(
      find.widgetWithText(FilledButton, 'Connect'),
    );
    expect(title.left, platform.left);
    expect(platform.left, cancel.left);
    expect(connect.right, platform.right);
    expect(cancel.width, closeTo(connect.width, .01));
    expect(cancel.height, connect.height);
    expect(name.top - platform.bottom, 16);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('compact cards use live status and wake the correct TV', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });

    final provider = FakeWakeProvider(requiresMac: true);
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..register(provider),
    );
    final bedroom = RemoteDevice(
      id: 'bedroom',
      providerId: tv.providerId,
      name: 'Bedroom TV',
      endpoints: [Uri.parse('wss://192.168.1.21:3001')],
      metadata: {'macAddress': '12:34:56:78:90:ab'},
    );
    await app.savedDevices.save(tv);
    await app.savedDevices.save(bedroom);
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));

    expect(find.text('CONFIGURED DISPLAYS (2)'), findsOneWidget);
    expect(find.text('0 Connected'), findsOneWidget);
    expect(find.byTooltip('Wake device'), findsOneWidget);
    expect(find.byTooltip('Open remote'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Wake device'));
    await tester.pumpAndSettle();
    expect(provider.wakes, 1);
    expect(provider.wakeTarget?.id, bedroom.id);
    expect(app.connection.state.value, DeviceConnectionState.connected);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Devices'));
    await tester.pumpAndSettle();
    expect(find.text('1 Connected'), findsOneWidget);
    expect(find.byTooltip('Open remote'), findsOneWidget);
    expect(find.byTooltip('Wake device'), findsNothing);

    await tester.tap(find.byTooltip('Bedroom TV options'));
    await tester.pumpAndSettle();
    expect(find.text('View details'), findsOneWidget);
    expect(find.text('Customize remote'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final disconnecting = app.connection.disconnect();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await disconnecting;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
