import 'dart:io';

import '../support/start_nearby_search.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:universal_remote_app/presentation/views/devices/widgets/discovery_progress.dart';

import '../support/memory_storage.dart';
import '../support/fixture_protocols.dart';
import '../support/pending_discovery_provider.dart';
import '../support/test_device.dart';

void main() {
  testWidgets(
    'search shows visible progress and disables repeated searches until discovery finishes',
    (tester) async {
      final provider = PendingDiscoveryProvider();
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..registerDefinition(provider.definition),
        discoveryProtocols: fixtureProtocols([provider]),
      );
      await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
      expect(find.byType(DiscoveryProgress), findsNothing);
      await startNearbySearch(tester);
      await tester.pump();
      await tester.pump();
      expect(find.text(DiscoveryProgress.label), findsOneWidget);
      expect(find.byType(DiscoveryProgress), findsOneWidget);
      expect(
        tester.getRect(find.byType(DiscoveryProgress)).bottom,
        lessThan(tester.getRect(find.text('Cancel search')).top),
      );
      expect(find.text('Cancel search'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(provider.calls, 1);
      expect(find.byType(DiscoveryProgress), findsOneWidget);
      provider.response.complete([tv]);
      await tester.pumpAndSettle();
      expect(find.byType(DiscoveryProgress), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(DiscoveryProgress.label), findsNothing);
      expect(find.text('Living room'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('a failed search replaces progress with the actionable error', (
    tester,
  ) async {
    final provider = PendingDiscoveryProvider();
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..registerDefinition(provider.definition),
      discoveryProtocols: fixtureProtocols([provider]),
    );
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await startNearbySearch(tester);
    await tester.pump();
    await tester.pump();
    expect(find.byType(DiscoveryProgress), findsOneWidget);
    provider.response.completeError(
      const SocketException('unreachable', osError: OSError('unreachable', 65)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DiscoveryProgress), findsNothing);
    expect(find.text('No network route'), findsOneWidget);
    expect(find.text('Search again'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
