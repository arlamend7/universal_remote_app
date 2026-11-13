import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/domains/session/services/active_session.dart';

import '../support/fake_interstitial_advertising.dart';
import '../support/fake_rewarded_advertising.dart';
import '../support/memory_storage.dart';

void main() {
  testWidgets('uses elapsed foreground time and saves on schedule', (
    tester,
  ) async {
    final storage = MemoryStorage();
    await storage.write(ActiveSession.storageKey, '{"remainingMs":1800000}');
    final startedAt = tester.binding.clock.now();
    Duration now() => tester.binding.clock.now().difference(startedAt);
    final session = ActiveSession(storage, FakeRewardedAdvertising(), now: now);
    await session.restore();
    var changes = 0;
    session.addListener(() => changes++);
    expect(session.remaining, const Duration(minutes: 30));
    session.setForeground(true);
    const startingBalance = Duration(minutes: 30);
    const checkpoint = ActiveSession.checkpoint;
    const second = Duration(seconds: 1);
    await tester.pump(checkpoint - second);
    expect(session.remaining, startingBalance - checkpoint + second);
    expect(_savedTime(storage), 1800000);
    expect(storage.writes, [ActiveSession.storageKey]);
    await tester.pump(second);
    final checkpointBalance = startingBalance - checkpoint;
    expect(_savedTime(storage), checkpointBalance.inMilliseconds);
    await tester.pump(const Duration(seconds: 9));
    expect(_savedTime(storage), checkpointBalance.inMilliseconds);
    expect(storage.writes, hasLength(2));
    expect(changes, 1);

    final restarted = ActiveSession(
      storage,
      FakeRewardedAdvertising(),
      now: now,
    );
    await restarted.restore();
    expect(restarted.remaining - session.remaining, const Duration(seconds: 9));

    session.setForeground(false);
    session.setForeground(false);
    await tester.pump(const Duration(hours: 1));
    final pausedBalance = checkpointBalance - const Duration(seconds: 9);
    expect(_savedTime(storage), pausedBalance.inMilliseconds);
    expect(storage.writes, hasLength(3));
    expect(changes, 2);
    expect(session.remaining, pausedBalance);
    session.setForeground(true);
    await tester.pump(const Duration(seconds: 2));
    expect(session.remaining, pausedBalance - const Duration(seconds: 2));
    await session.close();
    expect(_savedTime(storage), session.remaining.inMilliseconds);
    await restarted.close();
  });

  testWidgets('warns once, expires, and grants only one confirmed reward', (
    tester,
  ) async {
    final storage = MemoryStorage();
    await storage.write(ActiveSession.storageKey, '{"remainingMs":61000}');
    final startedAt = tester.binding.clock.now();
    Duration now() => tester.binding.clock.now().difference(startedAt);
    final ads = FakeRewardedAdvertising();
    final session = ActiveSession(storage, ads, now: now);
    await session.restore();
    session.setForeground(true);
    await tester.pump(const Duration(seconds: 1));
    expect(session.warningDue, isTrue);
    session.acknowledgePrompt();
    expect(session.warningDue, isFalse);

    final declined = session.requestExtension(canPresent: () => true);
    final staleReward = ads.earn!;
    await tester.pump(const Duration(seconds: 10));
    expect(session.remaining, const Duration(minutes: 1));
    ads.dismiss();
    expect(await declined, isFalse);
    await tester.pump(const Duration(minutes: 1));
    expect(session.expired, isTrue);
    expect(_savedTime(storage), 0);
    final writesAtExpiration = storage.writes.length;
    await tester.pump(const Duration(minutes: 5));
    expect(storage.writes, hasLength(writesAtExpiration));

    final request = session.requestExtension(canPresent: () => true);
    staleReward();
    expect(session.expired, isTrue);
    ads.earn!();
    ads.earn!();
    ads.dismiss();
    expect(await request, isTrue);
    expect(session.remaining, const Duration(hours: 2));
    expect(session.canExtend, isFalse);
    expect(_savedTime(storage), 7200000);
    expect(storage.writes, hasLength(writesAtExpiration + 1));
    await tester.pump(const Duration(minutes: 118, seconds: 59));
    expect(session.canExtend, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(session.canExtend, isTrue);
    await session.close();
  });

  testWidgets(
    'interstitials wait twenty minutes and respect the two-hour reward',
    (tester) async {
      final storage = MemoryStorage();
      final ads = FakeInterstitialAdvertising()..available = false;
      final reward = FakeRewardedAdvertising();
      final start = tester.binding.clock.now();
      final session = ActiveSession(
        storage,
        reward,
        interstitial: ads,
        now: () => tester.binding.clock.now().difference(start),
      );
      await session.restore();
      session.setForeground(true);
      await tester.pump(const Duration(minutes: 19));
      await session.showInterstitial(canPresent: () => true);
      expect(ads.presentations, 0);
      session.setForeground(false);
      await tester.pump(const Duration(hours: 1));
      session.setForeground(true);
      await tester.pump(const Duration(minutes: 1));
      expect(ads.presentations, 0);
      await session.showInterstitial(canPresent: () => false);
      expect(await session.showInterstitial(canPresent: () => true), isFalse);
      ads.available = true;
      expect(await session.showInterstitial(canPresent: () => true), isFalse);
      expect(ads.presentations, 0);
      await session.showInterstitial(canPresent: () => true);
      await session.showInterstitial(canPresent: () => true);
      expect(ads.presentations, 1);

      final extension = session.requestExtension(canPresent: () => true);
      reward.earn!();
      reward.dismiss();
      expect(await extension, isTrue);
      await tester.pump(const Duration(minutes: 119));
      await session.showInterstitial(canPresent: () => true);
      expect(ads.presentations, 1);
      await tester.pump(const Duration(minutes: 1));
      expect(session.expired, isTrue);
      await session.showInterstitial(canPresent: () => true);
      expect(ads.presentations, 1);
      await tester.pump(const Duration(minutes: 20));
      await session.showInterstitial(canPresent: () => true);
      expect(ads.presentations, 2);
      await session.close();
    },
  );

  testWidgets('restores the saved interstitial delay across restarts', (
    tester,
  ) async {
    final storage = MemoryStorage();
    await storage.write(
      ActiveSession.storageKey,
      '{"remainingMs":0,"interstitialWaitMs":300000}',
    );
    final start = tester.binding.clock.now();
    Duration now() => tester.binding.clock.now().difference(start);
    final first = ActiveSession(
      storage,
      FakeRewardedAdvertising(),
      interstitial: FakeInterstitialAdvertising(),
      now: now,
    );
    await first.restore();
    first.setForeground(true);
    await tester.pump(const Duration(minutes: 4, seconds: 59));
    expect(await first.showInterstitial(canPresent: () => true), isFalse);
    await first.close();

    final restarted = ActiveSession(
      storage,
      FakeRewardedAdvertising(),
      interstitial: FakeInterstitialAdvertising(),
      now: now,
    );
    await restarted.restore();
    restarted.setForeground(true);
    await tester.pump(const Duration(seconds: 1));
    expect(await restarted.showInterstitial(canPresent: () => true), isTrue);
    await restarted.close();
  });
}

int _savedTime(MemoryStorage storage) {
  final snapshot = jsonDecode(storage.values[ActiveSession.storageKey]!);
  return snapshot['remainingMs'] as int;
}
