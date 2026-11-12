import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:universal_remote_app/presentation/views/discovery/modals/device_discovery_sheet.dart';

import '../support/start_nearby_search.dart';

import '../support/memory_storage.dart';
import '../support/fixture_protocols.dart';
import '../support/fake_provider.dart';
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
        registry: ProviderRegistry()..registerDefinition(provider.definition),
        discoveryProtocols: fixtureProtocols([provider]),
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
      await startNearbySearch(tester);
      await tester.pump();
      await tester.pump();
      provider.response.complete([tv, tv]);
      await tester.pumpAndSettle();
      expect(find.byType(DeviceDiscoverySheet), findsOneWidget);
      expect(find.text('Connect'), findsNothing);
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
  testWidgets('failed discovery has diagnostics and no empty-results message', (
    tester,
  ) async {
    final provider = PendingDiscoveryProvider();
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..registerDefinition(provider.definition),
      discoveryProtocols: fixtureProtocols([provider]),
      acquireNetwork: () async {},
      releaseNetwork: () async {},
    );
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await startNearbySearch(tester);
    await tester.pump();
    provider.response.completeError(StateError('private TV data'));
    await tester.pumpAndSettle();

    final sheet = find.byType(DeviceDiscoverySheet);
    expect(find.text('No Displays Found'), findsNothing);
    expect(find.textContaining('Network discovery failed'), findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Connect by IP')),
      findsOneWidget,
    );
    await tester.tap(find.text('Search details'));
    await tester.pumpAndSettle();
    expect(find.textContaining('providerException'), findsOneWidget);
    expect(find.textContaining('private TV data'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('a failed provider leaves a discovered TV available', (
    tester,
  ) async {
    final failing = PendingDiscoveryProvider(id: 'broken');
    final working = FakeProvider();
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()
        ..registerDefinition(working.definition)
        ..registerDefinition(failing.definition),
      discoveryProtocols: fixtureProtocols([working, failing]),
      acquireNetwork: () async {},
      releaseNetwork: () async {},
    );
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await startNearbySearch(tester);
    await tester.pump();
    failing.response.completeError(StateError('Unavailable'));
    await tester.pumpAndSettle();

    expect(find.text(tv.name), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.textContaining('Network discovery failed'), findsNothing);
    expect(find.text('No Displays Found'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('closing discovery cancels and ignores late results', (
    tester,
  ) async {
    final provider = PendingDiscoveryProvider();
    var releases = 0;
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..registerDefinition(provider.definition),
      discoveryProtocols: fixtureProtocols([provider]),
      acquireNetwork: () async {},
      releaseNetwork: () async {
        releases++;
      },
    );
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await startNearbySearch(tester);
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
