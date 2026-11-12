import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/app_dependencies.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  testWidgets(
    'welcome persists until a setup action, then preparation opens on relaunch',
    (tester) async {
      final storage = MemoryStorage();
      await _launch(tester, storage);
      expect(find.text('Welcome to your TV'), findsOneWidget);
      expect(find.text('Find Devices'), findsNothing);
      await tester.ensureVisible(find.text('Light'));
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to your TV'), findsOneWidget);
      expect(await storage.read('settings.theme'), 'light');
      await _close(tester);

      await _launch(tester, storage);
      expect(find.text('Welcome to your TV'), findsOneWidget);
      await tester.tap(find.text('Configure later'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to your TV'), findsNothing);
      expect(find.text('Preparation'), findsOneWidget);
      expect(find.text('Search for devices'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await _close(tester);

      final app = await _launch(tester, storage);
      expect(find.text('Welcome to your TV'), findsNothing);
      expect(find.text('Preparation'), findsOneWidget);
      expect(app.discovery.searchId, 0);
      await _close(tester);
    },
  );

  testWidgets('Find Nearby TVs opens preparation before starting a scan', (
    tester,
  ) async {
    final storage = MemoryStorage();
    final app = await _launch(tester, storage);
    await tester.tap(find.text('Find Nearby TVs'));
    await tester.pumpAndSettle();

    expect(find.text('STEP 1 OF 4'), findsOneWidget);
    expect(find.text('Preparation'), findsOneWidget);
    expect(app.discovery.searchId, 0);

    final search = find.widgetWithText(FilledButton, 'Search for devices');
    expect(tester.widget<FilledButton>(search).onPressed, isNull);
    await tester.tap(find.text('My TV is on'));
    await tester.pump();
    await tester.tap(search);
    await tester.pumpAndSettle();

    expect(find.text('STEP 2 OF 4'), findsOneWidget);
    expect(app.discovery.searchId, 1);
    await _close(tester);

    final relaunched = await _launch(tester, storage);
    expect(find.text('STEP 1 OF 4'), findsOneWidget);
    expect(find.text('Welcome to your TV'), findsNothing);
    expect(relaunched.discovery.searchId, 0);
    await _close(tester);
  });

  testWidgets('removing the last registered TV redirects from Settings', (
    tester,
  ) async {
    final storage = MemoryStorage();
    final app = await AppBootstrap.initialize(
      storage: storage,
      registry: ProviderRegistry(),
    );
    await app.savedDevices.save(tv);
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    expect(find.text('APPEARANCE'), findsOneWidget);

    await app.savedDevices.forget(tv);
    await tester.pumpAndSettle();
    expect(find.text('Preparation'), findsOneWidget);
    expect(find.text('Welcome to your TV'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    await _close(tester);
  });
}

Future<AppDependencies> _launch(
  WidgetTester tester,
  MemoryStorage storage,
) async {
  final app = await AppBootstrap.initialize(
    storage: storage,
    registry: ProviderRegistry(),
    acquireNetwork: () async {},
    releaseNetwork: () async {},
  );
  await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
  await tester.pumpAndSettle();
  return app;
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}
