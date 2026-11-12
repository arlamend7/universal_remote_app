import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';

import '../support/memory_storage.dart';

void main() {
  testWidgets('offline startup shows a full-screen prompt before welcome', (
    tester,
  ) async {
    var transport = 'offline';
    _mockNetwork(tester, () => transport);
    await _launch(tester, MemoryStorage());

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('No local network').hitTestable(), findsOneWidget);
    final wifiIcon = find.byIcon(Icons.wifi_off_rounded);
    expect(
      tester.widget<Icon>(wifiIcon).color,
      Theme.of(tester.element(wifiIcon)).colorScheme.primary,
    );
    expect(find.text('Find Nearby TVs').hitTestable(), findsNothing);

    await tester.tap(find.text('Connection details'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('A wired connection works too.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    transport = 'wifi';
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Welcome to your TV').hitTestable(), findsOneWidget);
    await _close(tester);
  });

  testWidgets(
    'Continue offline spans both actions and dismisses for this launch',
    (tester) async {
      var reads = 0;
      _mockNetwork(tester, () {
        reads++;
        return 'offline';
      });
      final storage = MemoryStorage();
      await _launch(tester, storage);

      final retry = tester.getRect(
        find.widgetWithText(OutlinedButton, 'Try again'),
      );
      final wifi = tester.getRect(find.byType(FilledButton).hitTestable());
      final continueOffline = find.widgetWithText(
        OutlinedButton,
        'Continue offline',
      );
      final row = tester.getRect(continueOffline);
      expect(row.left, closeTo(retry.left, 1));
      expect(row.right, closeTo(wifi.right, 1));
      expect(row.top - retry.bottom, closeTo(12, 1));

      await tester.tap(continueOffline);
      await tester.pumpAndSettle();
      expect(find.text('Welcome to your TV').hitTestable(), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(Dialog), findsNothing);
      expect(reads, 1);
      await _close(tester);

      await _launch(tester, storage);
      expect(find.byType(Dialog), findsOneWidget);
      await _close(tester);
    },
  );

  testWidgets('restoring Ethernet returns to Preparation without a scan', (
    tester,
  ) async {
    var transport = 'offline';
    _mockNetwork(tester, () => transport);
    final storage = MemoryStorage();
    await storage.write('settings.welcomeCompleted', 'true');
    await _launch(tester, storage);
    expect(find.byType(Dialog), findsOneWidget);

    transport = 'ethernet';
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('STEP 1 OF 4').hitTestable(), findsOneWidget);
    expect(find.text('Find Devices'), findsNothing);
    await _close(tester);
  });
}

void _mockNetwork(WidgetTester tester, String Function() transport) {
  const channel = MethodChannel('br.net.devcom.universal_remote/local_network');
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    channel,
    (call) async => {'transport': transport()},
  );
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
}

Future<void> _launch(WidgetTester tester, MemoryStorage storage) async {
  final dependencies = await AppBootstrap.initialize(
    storage: storage,
    registry: ProviderRegistry(),
  );
  await tester.pumpWidget(UniversalRemoteApp(dependencies: dependencies));
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}
