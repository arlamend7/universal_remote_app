import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:universal_remote_app/domains/session/services/active_session.dart';
import 'package:universal_remote_app/presentation/views/session/session_reward_highlight.dart';
import 'package:universal_remote_app/presentation/views/session/session_time_sheet.dart';

import '../support/fake_interstitial_advertising.dart';
import '../support/fake_provider.dart';
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
    // The footer shows hours and minutes, rounded up: 81 s reads 00:02.
    expect(find.text('00:02'), findsOneWidget);
    final devicesPage = tester.element(find.text('CONFIGURED DISPLAYS (1)'));
    // Discovery is busy while the final minute starts, so the warning waits.
    app.discovery.busy.value = true;
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('00:02'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(
      storage.values[ActiveSession.storageKey],
      contains('"remainingMs":81000'),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      storage.values[ActiveSession.storageKey],
      contains('"remainingMs":51000'),
      reason: 'The balance is saved every checkpoint (30 s).',
    );
    expect(
      tester.element(find.text('CONFIGURED DISPLAYS (1)')),
      same(devicesPage),
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Ad options'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(SessionTimeSheet), findsNothing);
    app.discovery.busy.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Ad-free time almost over'), findsOneWidget);
    expect(find.text('Your remote always works'), findsOneWidget);
    final extend = find.widgetWithText(FilledButton, 'Watch ad');
    final dismiss = find.widgetWithText(OutlinedButton, 'Not now');
    expect(tester.getSize(extend), tester.getSize(dismiss));
    final dismissLabel = tester.element(find.text('Not now'));
    expect(
      DefaultTextStyle.of(dismissLabel).style.color,
      Theme.of(dismissLabel).colorScheme.primary,
    );
    final title = tester.getCenter(find.text('Ad-free time almost over'));
    final close = find.byTooltip('Close');
    final closeCenter = tester.getCenter(close);
    expect(title.dx, closeTo(195, 1));
    expect(closeCenter.dy, closeTo(title.dy, 1));
    expect(closeCenter.dx, greaterThan(title.dx));
    final countdown = find.descendant(
      of: find.byType(SessionTimeSheet),
      matching: find.textContaining(RegExp(r'^00:[0-5][0-9]$')),
    );
    final seconds = int.parse(
      tester.widget<Text>(countdown).data!.substring(3),
    );
    expect(
      tester.widget<Text>(countdown).style!.color,
      Theme.of(tester.element(countdown)).colorScheme.primary,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      int.parse(tester.widget<Text>(countdown).data!.substring(3)),
      seconds - 1,
    );
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.byType(SessionTimeSheet), findsNothing);
    expect(ads.requests, 0);

    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.byType(SessionTimeSheet), findsNothing);
    expect(find.text('Ads'), findsOneWidget);
    await tester.tap(find.text('Devices'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FilledButton, 'Connect').hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Ad options'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final animatedReward = find.descendant(
      of: find.byType(SessionRewardHighlight),
      matching: find.byType(Transform),
    );
    expect(
      tester.widget<Transform>(animatedReward).transform.entry(0, 0),
      lessThan(1),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Transform>(animatedReward).transform.entry(0, 0), 1);
    expect(find.text('Ad-free Pass'), findsOneWidget);
    expect(find.text('YOUR REWARD'), findsOneWidget);
    expect(find.text('2 hours'), findsOneWidget);
    expect(find.text('Fewer interruptions'), findsOneWidget);
    final sheetContent = find.descendant(
      of: find.byType(SessionTimeSheet),
      matching: find.byType(SingleChildScrollView),
    );
    final remoteDetails = find.text(
      'Keep controlling your TV and connecting devices.',
    );
    await tester.ensureVisible(remoteDetails);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(sheetContent).bottom,
      greaterThanOrEqualTo(tester.getRect(remoteDetails).bottom),
    );
    expect(
      find.textContaining(
        'Full-screen ads may appear every 20 minutes of active app use.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Watch ad'));
    await tester.pump();
    expect(ads.requests, 1);
    ads.earn!();
    ads.dismiss();
    await tester.pumpAndSettle();
    expect(find.byType(SessionTimeSheet), findsNothing);
    expect(app.session!.remaining, greaterThan(const Duration(minutes: 119)));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('eligible interstitials wait for Settings or an editor exit', (
    tester,
  ) async {
    final interstitial = FakeInterstitialAdvertising();
    final start = tester.binding.clock.now();
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()
        ..registerDefinition(FakeProvider().definition),
      rewardedAdvertising: FakeRewardedAdvertising(),
      interstitialAdvertising: interstitial,
      sessionClock: () => tester.binding.clock.now().difference(start),
    );
    await app.savedDevices.save(tv);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 20));
    expect(interstitial.presentations, 0);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Remote'));
    await tester.pumpAndSettle();
    expect(interstitial.presentations, 0);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    expect(interstitial.presentations, 1);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Devices'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Connect'), findsOneWidget);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    expect(interstitial.presentations, 1);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Devices'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tv.name));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Customize remote'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 20));
    expect(interstitial.presentations, 1);
    await tester.tap(find.byTooltip('Back to remote'));
    await tester.pumpAndSettle();
    expect(interstitial.presentations, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  });
}
