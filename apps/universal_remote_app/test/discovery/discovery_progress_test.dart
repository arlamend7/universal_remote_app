import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';

import '../support/memory_storage.dart';
import '../support/pending_discovery_provider.dart';
import '../support/test_device.dart';

void main() {
  testWidgets(
    'search shows visible progress and disables repeated searches until discovery finishes',
    (tester) async {
      final provider = PendingDiscoveryProvider();
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..register(provider),
      );
      await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.tap(find.text('Find Nearby Devices'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Searching for LG TVs…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Cancel search'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(provider.calls, 1);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      provider.response.complete([tv]);
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Searching for LG TVs…'), findsNothing);
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
      registry: ProviderRegistry()..register(provider),
    );
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.tap(find.text('Find Nearby Devices'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    provider.response.completeError(
      const SocketException('unreachable', osError: OSError('unreachable', 65)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('code 65'), findsOneWidget);
    expect(find.text('Search again'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
