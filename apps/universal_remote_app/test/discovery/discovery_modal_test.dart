import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:universal_remote_app/presentation/views/discovery/modals/device_discovery_sheet.dart';

import '../support/memory_storage.dart';
import '../support/capture_design.dart';
import '../support/pending_discovery_provider.dart';
import '../support/test_device.dart';

void main() {
  setUpAll(loadDesignFont);
  testWidgets(
    'registered TV stays out of new results and the Devices page keeps its geometry',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final provider = PendingDiscoveryProvider();
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..register(provider),
        acquireNetwork: () async {},
        releaseNetwork: () async {},
      );
      await app.savedDevices.save(tv);
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: UniversalRemoteApp(dependencies: app),
        ),
      );
      final rowPosition = tester.getTopLeft(find.text('Living room'));
      await tester.tap(find.text('Find Nearby Devices'));
      await tester.pump();
      await tester.pump();
      provider.response.complete([tv, tv]);
      await tester.pumpAndSettle();
      expect(find.byType(DeviceDiscoverySheet), findsOneWidget);
      expect(find.text('Add'), findsNothing);
      expect(find.text('Already added (1)'), findsOneWidget);
      await captureDesign(tester, capture, '20-discovery-modal');
      expect(tester.getTopLeft(find.text('Living room')), rowPosition);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(DeviceDiscoverySheet), findsNothing);
      expect(app.savedDevices.devices.value, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('closing discovery cancels and ignores late results', (
    tester,
  ) async {
    final provider = PendingDiscoveryProvider();
    var releases = 0;
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..register(provider),
      acquireNetwork: () async {},
      releaseNetwork: () async {
        releases++;
      },
    );
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.tap(find.text('Find Nearby Devices'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(app.discovery.busy.value, isTrue);
    expect(provider.token!.isCancelled, isFalse);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(provider.token!.isCancelled, isTrue);
    expect(releases, 1);
    provider.response.complete([tv]);
    await tester.pumpAndSettle();
    expect(app.discovery.devices.value, isEmpty);
    expect(find.text('Living room'), findsNothing);
    expect(app.discovery.busy.value, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
