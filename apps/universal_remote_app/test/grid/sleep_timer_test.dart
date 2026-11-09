import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';

import '../support/fake_provider.dart';
import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  testWidgets('local sleep timer cancels when the selected TV changes', (
    tester,
  ) async {
    final provider = FakeProvider(enabledControls: true);
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..registerDefinition(provider.definition),
    );
    await app.savedDevices.save(tv);
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.tap(find.text('Living room'));
    await tester.pumpAndSettle();
    final control = provider.last!.powerControl;
    app.sleep.schedule(tv, const Duration(minutes: 1));
    expect(app.sleep.deadline.value, isNotNull);
    app.connection.selected.value = RemoteDevice(
      id: 'other',
      name: 'Bedroom',
      providerId: tv.providerId,
      endpoints: tv.endpoints,
    );
    await tester.pump(const Duration(minutes: 2));
    expect(control.shutdowns, 0);
    expect(app.sleep.deadline.value, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  });
}
