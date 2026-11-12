import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';

import 'package:universal_remote_app/presentation/views/discovery/pages/device_preparation_page.dart';

import '../support/memory_storage.dart';

void main() {
  for (final (size, scale) in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 1.4),
  ]) {
    testWidgets('preparation actions fit at $size and $scale', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry(),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: DevicePreparationPage(dependencies: app),
        ),
      );
      final search = find.widgetWithText(FilledButton, 'Search for devices');
      expect(tester.widget<FilledButton>(search).onPressed, isNull);
      await tester.ensureVisible(find.text('My TV is on'));
      await tester.tap(find.text('My TV is on'));
      await tester.pump();
      expect(tester.widget<FilledButton>(search).onPressed, isNotNull);
      expect(search.hitTestable(), findsOneWidget);
      expect(find.text('Connection details').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      unawaited(app.dispose());
      await tester.pumpAndSettle();
    });
  }
  testWidgets(
    'the network checks itself and reveals the SSID after permission',
    (tester) async {
      const channel = MethodChannel(
        'br.net.devcom.universal_remote/local_network',
      );
      final messenger = tester.binding.defaultBinaryMessenger;
      var transport = 'wifi';
      var authorized = false;
      var requests = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'requestNamePermission') {
          requests++;
          authorized = true;
          return null;
        }
        return {
          'transport': transport,
          'canRequestName': !authorized,
          if (authorized && transport == 'wifi') 'name': 'Home_WiFi_5G',
        };
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry(),
      );
      await tester.pumpWidget(
        MaterialApp(home: DevicePreparationPage(dependencies: app)),
      );
      await tester.pumpAndSettle();

      final networkCard = find.widgetWithText(ListTile, 'Same local network');
      final check = find.descendant(
        of: networkCard,
        matching: find.byType(Checkbox),
      );
      expect(tester.widget<Checkbox>(check).value, isTrue);
      expect(tester.widget<Checkbox>(check).onChanged, isNull);
      expect(find.text('Wi-Fi connected'), findsOneWidget);
      expect(requests, 0);

      await tester.tap(find.text('Show Wi-Fi name'));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(find.text('Home_WiFi_5G'), findsOneWidget);

      transport = 'offline';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(check).value, isFalse);
      expect(find.text('Home_WiFi_5G'), findsNothing);
      expect(find.text('No Wi-Fi or Ethernet connection'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      unawaited(app.dispose());
      await tester.pumpAndSettle();
    },
  );
}
