import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:universal_remote_app/domains/session/services/active_session.dart';
import 'package:universal_remote_app/presentation/views/session/session_time_sheet.dart';

import '../support/fake_rewarded_advertising.dart';
import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  testWidgets('footer refreshes locally and warning waits for discovery', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final ads = FakeRewardedAdvertising();
    final storage = MemoryStorage();
    await storage.write(ActiveSession.storageKey, '{"remainingMs":81000}');
    final start = tester.binding.clock.now();
    final app = await AppBootstrap.initialize(
      storage: storage,
      rewardedAdvertising: ads,
      sessionClock: () => tester.binding.clock.now().difference(start),
    );
    await app.savedDevices.save(tv);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.pumpAndSettle();
    expect(find.text('01:21'), findsOneWidget);
    final devicesPage = tester.element(find.text('CONFIGURED DISPLAYS (1)'));
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('01:21'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('01:11'), findsOneWidget);
    expect(
      tester.element(find.text('CONFIGURED DISPLAYS (1)')),
      same(devicesPage),
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Session time'), findsOneWidget);

    app.discovery.busy.value = true;
    await tester.pump(const Duration(seconds: 12));
    expect(find.byType(SessionTimeSheet), findsNothing);
    app.discovery.busy.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Session almost over'), findsOneWidget);
    final countdown = find.descendant(
      of: find.byType(SessionTimeSheet),
      matching: find.textContaining(RegExp(r'^00:[0-5][0-9]$')),
    );
    final seconds = int.parse(
      tester.widget<Text>(countdown).data!.substring(3),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      int.parse(tester.widget<Text>(countdown).data!.substring(3)),
      seconds - 1,
    );
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionTimeSheet), findsNothing);
    expect(ads.requests, 0);

    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('Session ended'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devices'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FilledButton, 'Connect').hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.ondemand_video_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watch ad · +30 min'));
    await tester.pump();
    expect(ads.requests, 1);
    ads.earn!();
    ads.dismiss();
    await tester.pumpAndSettle();
    expect(find.byType(SessionTimeSheet), findsNothing);
    expect(app.session!.remaining, greaterThan(const Duration(minutes: 29)));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
