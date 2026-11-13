import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';

import '../support/capture_design.dart';
import '../support/fake_provider.dart';
import '../support/memory_storage.dart';
import '../support/unavailable_secure_storage.dart';
import '../support/test_device.dart';

void main() {
  setUpAll(loadDesignFont);
  testWidgets(
    'compact rows hide details; layout drafts cancel or save for one TV; preferences are a sheet',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final provider = FakeProvider(enabledControls: true);
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..registerDefinition(provider.definition),
      );
      final bedroom = RemoteDevice(
        id: 'bedroom',
        name: 'Bedroom',
        providerId: provider.id,
        endpoints: tv.endpoints,
      );
      await app.savedDevices.save(tv);
      await app.savedDevices.save(bedroom);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: UniversalRemoteApp(dependencies: app),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      expect(find.text('Network wake'), findsNothing);
      await captureDesign(tester, key, '01-devices');
      await tester.tap(find.byTooltip('Living room info'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AppSheet),
          matching: find.text('192.168.1.20'),
        ),
        findsOneWidget,
      );
      await captureDesign(tester, key, '02-device-details');
      await tester.tap(find.text('Customize remote'));
      await tester.pumpAndSettle();
      await captureDesign(tester, key, '03-layout-editor');
      await _removeInputs(tester);
      await tester.tap(find.byTooltip('Back to remote').last);
      await tester.pumpAndSettle();
      expect(app.grids.forDevice(tv), isNull);
      expect(find.text('Device info'), findsNothing);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      await tester.tap(find.byTooltip('Customize remote'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-control')));
      await tester.pumpAndSettle();
      await captureDesign(tester, key, '04-add-controls');
      await tester.tap(find.byTooltip('Close library'));
      await tester.pumpAndSettle();
      await _removeInputs(tester);
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(
        app.grids
            .forDevice(tv)!
            .items
            .any((item) => item.definitionId == 'inputs'),
        isFalse,
      );
      expect(app.grids.forDevice(bedroom), isNull);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Inputs'), findsNothing);
      await captureDesign(tester, key, '05-remote');
      await tester.tap(find.text('Devices'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await captureDesign(tester, key, '06-preferences');
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'reported app/channel context updates without blocking controls when feedback disappears',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final provider = FakeProvider(enabledControls: true);
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..registerDefinition(provider.definition),
      );
      await app.savedDevices.save(tv);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: UniversalRemoteApp(dependencies: app),
        ),
      );
      await tester.tap(find.text('Living room'));
      await tester.pumpAndSettle();
      expect(find.text('YouTube'), findsOneWidget);
      await captureDesign(tester, key, '08-default-remote');
      provider.last!.contentControl.update(
        const CurrentContent(
          appId: 'com.webos.app.livetv',
          liveTv: true,
          appName: 'Live TV',
          channelName: 'CBC',
          channelNumber: '7.1',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('7.1 · CBC'), findsOneWidget);
      await captureDesign(tester, key, '09-live-channel');
      await tester.tap(find.byTooltip('Next channel'));
      await tester.pumpAndSettle();
      expect(provider.last!.channelControl.adjustments, 1);
      provider.last!.contentControl.unavailable = true;
      await app.connection.refreshContent();
      await tester.pumpAndSettle();
      expect(find.text('Current activity unavailable'), findsOneWidget);
      expect(app.connection.supports(RemoteCapability.volume), isTrue);
      expect(app.connection.supports(RemoteCapability.navigation), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'reopening restores the last TV without connecting or reading protected credentials',
    (tester) async {
      final storage = MemoryStorage();
      final provider = FakeProvider();
      final first = await AppBootstrap.initialize(
        storage: storage,
        registry: ProviderRegistry()..registerDefinition(provider.definition),
      );
      await first.savedDevices.save(
        copyDevice(tv, metadata: {'lastConnectedAt': '2026-01-01T00:00:00Z'}),
      );
      await first.dispose();
      final nextProvider = FakeProvider();
      final app = await AppBootstrap.initialize(
        storage: storage,
        credentialStorage: UnavailableSecureStorage(),
        registry: ProviderRegistry()
          ..registerDefinition(nextProvider.definition),
      );
      await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Disconnected'), findsOneWidget);
      expect(nextProvider.last, isNull);
      expect(find.text('Review TV certificate and pair'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    },
  );

  for (final size in [const Size(320, 640), const Size(1200, 800)]) {
    testWidgets('remote, details and editor fit $size with larger text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(() async {
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await tester.binding.setSurfaceSize(null);
      });
      final provider = FakeProvider(enabledControls: true);
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..registerDefinition(provider.definition),
      );
      await app.savedDevices.save(tv);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: UniversalRemoteApp(dependencies: app),
        ),
      );
      await tester.tap(find.text('Living room'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (size.width > 1000) {
        await captureDesign(tester, key, '07-desktop-remote');
      }
      await tester.tap(find.byTooltip('Customize remote'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('add-control')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close library'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back to remote').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devices'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    });
  }
}

Future<void> _removeInputs(WidgetTester tester) async {
  final remove = find.byTooltip('Remove Inputs');
  await tester.ensureVisible(remove);
  await tester.tap(remove);
  await tester.pumpAndSettle();
}
