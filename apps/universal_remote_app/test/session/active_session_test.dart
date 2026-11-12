import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/domains/session/services/active_session.dart';

import '../support/fake_rewarded_advertising.dart';
import '../support/memory_storage.dart';

void main() {
  testWidgets(
    'uses elapsed foreground time and checkpoints every ten seconds',
    (tester) async {
      final storage = MemoryStorage();
      final startedAt = tester.binding.clock.now();
      Duration now() => tester.binding.clock.now().difference(startedAt);
      final session = ActiveSession(
        storage,
        FakeRewardedAdvertising(),
        now: now,
      );
      await session.restore();
      var changes = 0;
      session.addListener(() => changes++);
      expect(session.remaining, const Duration(minutes: 30));
      session.setForeground(true);
      await tester.pump(const Duration(seconds: 9));
      expect(session.remaining, const Duration(minutes: 29, seconds: 51));
      expect(_savedTime(storage), 1800000);
      expect(storage.writes, [ActiveSession.storageKey]);
      await tester.pump(const Duration(seconds: 1));
      expect(_savedTime(storage), 1790000);
      await tester.pump(const Duration(seconds: 9));
      expect(_savedTime(storage), 1790000);
      expect(storage.writes, hasLength(2));
      expect(changes, 1);

      final restarted = ActiveSession(
        storage,
        FakeRewardedAdvertising(),
        now: now,
      );
      await restarted.restore();
      expect(
        restarted.remaining - session.remaining,
        const Duration(seconds: 9),
      );

      session.setForeground(false);
      session.setForeground(false);
      await tester.pump(const Duration(hours: 1));
      expect(_savedTime(storage), 1781000);
      expect(storage.writes, hasLength(3));
      expect(changes, 2);
      expect(session.remaining, const Duration(minutes: 29, seconds: 41));
      session.setForeground(true);
      await tester.pump(const Duration(seconds: 2));
      expect(session.remaining, const Duration(minutes: 29, seconds: 39));
      await session.close();
      expect(_savedTime(storage), 1779000);
      await restarted.close();
    },
  );

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
    expect(session.expirationDue, isTrue);
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
    expect(session.remaining, const Duration(minutes: 30));
    expect(session.canExtend, isFalse);
    expect(_savedTime(storage), 1800000);
    expect(storage.writes, hasLength(writesAtExpiration + 1));
    await tester.pump(const Duration(seconds: 59));
    expect(session.canExtend, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(session.canExtend, isTrue);
    await session.close();
  });
}

int _savedTime(MemoryStorage storage) {
  final snapshot = jsonDecode(storage.values[ActiveSession.storageKey]!);
  return snapshot['remainingMs'] as int;
}
