import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/presentation/views/devices/widgets/swipe_device_tile.dart';
import 'package:universal_remote_app/presentation/views/devices/widgets/device_category_badge.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:universal_remote_app/presentation/widgets/layout/page_title.dart';

import '../support/fake_wake_provider.dart';

import 'package:universal_remote_app/data/pairing/repositories/secure_credential_store.dart';

import '../support/integration_providers.dart';
import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  testWidgets(
    'floating Connect opens preparation and keeps IP setup available',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: integrationProviders(SecureCredentialStore(MemoryStorage())),
      );
      await app.savedDevices.save(tv);
      await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
      final heading = find.descendant(
        of: find.byType(PageTitle),
        matching: find.text('Devices'),
      );
      final addDevice = find.widgetWithText(FilledButton, 'Connect');
      expect(tester.getCenter(heading).dx, closeTo(195, 1));
      expect(find.text('Nearby'), findsNothing);
      expect(find.text('IP'), findsNothing);
      expect(tester.getRect(addDevice).top, greaterThan(700));
      expect(
        tester.getRect(addDevice).bottom,
        lessThan(tester.getRect(find.byType(NavigationBar)).top),
      );
      await tester.tap(addDevice);
      await tester.pumpAndSettle();
      expect(find.text('STEP 1 OF 4'), findsOneWidget);
      await tester.tap(find.text('Connect by IP'));
      await tester.pumpAndSettle();

      final title = tester.getRect(
        find.descendant(
          of: find.byType(AppSheet),
          matching: find.text('Connect by IP'),
        ),
      );
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
    },
  );

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
      registry: ProviderRegistry()..registerDefinition(provider.definition),
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
    final badges = find.byType(DeviceCategoryBadge);
    expect(
      tester
          .widgetList<DeviceCategoryBadge>(badges)
          .every((badge) => !badge.connected && !badge.possiblyAwake),
      isTrue,
    );
    app.discovery.recentDevices.value = [bedroom];
    await tester.pump();
    expect(
      tester
          .widgetList<DeviceCategoryBadge>(badges)
          .where((badge) => badge.possiblyAwake),
      hasLength(1),
    );
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

    await tester.tap(find.byTooltip('Bedroom TV info'));
    await tester.pumpAndSettle();
    expect(find.text('Device info'), findsOneWidget);
    expect(find.text('Customize remote'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final disconnecting = app.connection.disconnect();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await disconnecting;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('swipe reveals edit and confirmed delete clears saved data', (
    tester,
  ) async {
    final storage = MemoryStorage();
    final app = await AppBootstrap.initialize(storage: storage);
    await app.savedDevices.save(tv);
    await app.grids.save(tv, GridLayout([]));
    await app.savedDevices.credentials.write(tv.id, 'pairing-key');
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));

    final row = find.byType(SwipeDeviceTile);
    expect(find.text('192.168.1.20'), findsNothing);
    await tester.drag(row, const Offset(-180, 0));
    await tester.pumpAndSettle();
    expect(find.text('Edit').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Edit').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Connection settings'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.drag(row, const Offset(-180, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Delete Living room?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(app.savedDevices.devices.value, isEmpty);
    expect(app.grids.forDevice(tv), isNull);
    expect(await app.savedDevices.credentials.read(tv.id), isNull);
    expect(storage.values['saved-devices.v2'], isNot(contains(tv.id)));
    expect(storage.values['dashboards.v2'], isNot(contains(tv.id)));
    expect(row, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
