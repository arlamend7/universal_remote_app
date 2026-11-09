import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_lg_webos/remote_lg_webos.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';

import '../support/fake_controller.dart';
import '../support/memory_storage.dart';

void main() {
  testWidgets(
    'V2 sheet finds LG once, keeps unknown evidence, and connects only on tap',
    (tester) async {
      var scans = 0;
      var controllers = 0;
      final protocols = DiscoveryRegistry()
        ..register(DiscoveryProtocol.ssdp, (
          service,
          cancellation,
          observe,
        ) async {
          scans++;
          final reply = DiscoveryObservation(
            protocolId: DiscoveryProtocol.ssdp,
            serviceType: service,
            endpoint: Uri.parse('udp://192.168.1.23'),
            metadata: {'usn': 'uuid:test-tv', 'friendlyname': 'Test OLED'},
          );
          await observe(reply);
          await observe(reply);
          await observe(
            DiscoveryObservation(
              protocolId: DiscoveryProtocol.ssdp,
              serviceType: service,
            ),
          );
        });
      final providers = ProviderRegistry()
        ..registerDefinition(
          ProviderDefinition(
            identifier: const LgIdentifier(),
            createController: (device) {
              controllers++;
              return FakeController(device);
            },
          ),
        );
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: providers,
        discoveryProtocols: protocols,
        acquireNetwork: () async {},
        releaseNetwork: () async {},
      );
      await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
      await tester.tap(find.byTooltip('Find Nearby Devices'));
      await tester.pumpAndSettle();
      expect(find.text('Test OLED'), findsOneWidget);
      expect(find.text('1 unrecognized discovery responses'), findsOneWidget);
      expect(controllers, 0);
      expect(scans, 1);
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();
      expect(controllers, 1);
      expect(scans, 1);
      expect(
        app.savedDevices.registered.single.preferredProfile.providerId,
        'lg.webos',
      );
      final disconnecting = app.connection.disconnect();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await disconnecting;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
