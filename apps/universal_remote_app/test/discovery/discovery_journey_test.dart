import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:universal_remote_app/presentation/views/devices/modals/device_editor.dart';

import '../support/fake_provider.dart';
import '../support/fixture_protocols.dart';
import '../support/memory_storage.dart';
import '../support/start_nearby_search.dart';
import '../support/test_device.dart';

void main() {
  testWidgets('welcome offers manual IP before scanning', (tester) async {
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry(),
    );
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.tap(find.text('Connect by IP address'));
    await tester.pumpAndSettle();
    expect(find.byType(DeviceEditor), findsOneWidget);
    expect(app.discovery.searchId, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('permission denial can recover without restarting setup', (
    tester,
  ) async {
    final provider = FakeProvider();
    var allowed = false;
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..registerDefinition(provider.definition),
      discoveryProtocols: fixtureProtocols([provider]),
      acquireNetwork: () async {
        if (!allowed) {
          throw const DiscoveryOperationFailure(
            'authorize',
            'denied',
            code: 'localNetworkDenied',
          );
        }
      },
      releaseNetwork: () async {},
    );
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await startNearbySearch(tester);
    await tester.pumpAndSettle();
    expect(find.text('Local network permission needed'), findsOneWidget);
    expect(find.text('No Displays Found'), findsNothing);

    allowed = true;
    await tester.tap(find.text('Search again'));
    await tester.pumpAndSettle();
    expect(find.text(tv.name), findsOneWidget);
    expect(find.text('Local network permission needed'), findsNothing);
    await tester.tap(find.byTooltip('Device details'));
    await tester.pumpAndSettle();
    expect(find.text('Discovered via · SSDP'), findsOneWidget);
    expect(app.discovery.searchId, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('pairing retry and back preserve the selected TV', (
    tester,
  ) async {
    final provider = FakeProvider(
      startupFailure: const RemoteException(
        'pairing',
        'The TV denied pairing.',
      ),
    );
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..registerDefinition(provider.definition),
      discoveryProtocols: fixtureProtocols([provider]),
      acquireNetwork: () async {},
      releaseNetwork: () async {},
    );
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await startNearbySearch(tester);
    await tester.pumpAndSettle();
    final connect = find.widgetWithText(FilledButton, 'Connect');
    expect(tester.widget<FilledButton>(connect).onPressed, isNotNull);
    await tester.tap(connect);
    await tester.pumpAndSettle();
    expect(find.text('The TV denied pairing.'), findsOneWidget);
    final original = provider.last;

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(provider.last, isNot(same(original)));
    expect(provider.last?.device.id, tv.id);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(connect).onPressed, isNotNull);
    expect(app.discovery.searchId, 1);
    expect(app.savedDevices.devices.value, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
