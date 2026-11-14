import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  testWidgets('Drivers shows download only when an update is available', (
    tester,
  ) async {
    final app = await AppBootstrap.initialize(storage: MemoryStorage());
    await app.savedDevices.save(tv);
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    final drivers = find.widgetWithText(ListTile, 'Drivers');
    final chevron = find.descendant(
      of: drivers,
      matching: find.byIcon(Icons.chevron_right),
    );
    expect(chevron, findsOneWidget);
    app.driverUpdatesAvailable.value = true;
    await tester.pumpAndSettle();
    expect(chevron, findsNothing);
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    expect(find.text('Updates available'), findsOneWidget);
    app.driverUpdatesAvailable.value = false;
    await tester.pumpAndSettle();
    expect(chevron, findsOneWidget);
  });

  testWidgets('custom accent applies and persists only after confirmation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = MemoryStorage();
    final app = await AppBootstrap.initialize(storage: storage);
    final original = app.settings.accent.value;
    await app.savedDevices.save(tv);
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Light'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Dark'), findsOneWidget);
    expect(await storage.read('settings.theme'), 'light');

    expect(
      tester.getCenter(find.byTooltip('Turquoise')).dy,
      tester.getCenter(find.byTooltip('Custom Accent')).dy,
    );
    await tester.tap(find.text('Accent Color'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNWidgets(2));
    final hex = find.widgetWithText(TextField, 'Hex color');
    await tester.enterText(hex, '0BAD77');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(app.settings.accent.value, original);

    await tester.tap(find.text('Accent Color'));
    await tester.pumpAndSettle();
    await tester.enterText(hex, '0BAD77');
    await tester.tap(find.text('Apply Color'));
    await tester.pumpAndSettle();
    expect(app.settings.accent.value, 0xff0bad77);
    expect(await storage.read('settings.accent'), '${0xff0bad77}');
    expect(find.text('Custom Color'), findsOneWidget);

    await tester.tap(find.text('Auto-Reconnect'));
    await tester.pumpAndSettle();
    expect(app.settings.autoReconnect.value, isFalse);
    expect(await storage.read('settings.autoReconnect'), 'false');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
