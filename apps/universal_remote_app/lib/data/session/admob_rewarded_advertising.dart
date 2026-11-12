import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domains/session/contracts/rewarded_advertising.dart';
import 'admob_consent.dart';

final class AdMobRewardedAdvertising implements RewardedAdvertising {
  AdMobRewardedAdvertising(this._unitId, this._consent);

  final String _unitId;
  final AdMobConsent _consent;

  @override
  ValueListenable<bool> get privacyOptionsRequired =>
      _consent.privacyOptionsRequired;

  @override
  Future<void> showPrivacyOptions() => _consent.showPrivacyOptions();

  @override
  Future<void> show({
    required bool Function() canPresent,
    required void Function(bool) onVisible,
    required void Function() onEarned,
  }) async {
    if (!await _consent.canLoad(canPresentConsent: canPresent) ||
        !canPresent()) {
      return;
    }
    await _consent.initialize();
    if (!canPresent()) {
      return;
    }
    final ad = await _load();
    if (ad == null) {
      return;
    }
    try {
      if (canPresent()) {
        await _present(ad, onVisible, onEarned);
      }
    } finally {
      await ad.dispose();
    }
  }

  Future<RewardedAd?> _load() async {
    final loaded = Completer<RewardedAd?>();
    var waiting = true;
    await RewardedAd.load(
      adUnitId: _unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!waiting) {
            unawaited(ad.dispose());
            return;
          }
          loaded.complete(ad);
        },
        onAdFailedToLoad: (_) => loaded.complete(null),
      ),
    );
    try {
      return await loaded.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => null,
      );
    } finally {
      waiting = false;
    }
  }

  Future<void> _present(
    RewardedAd ad,
    void Function(bool) onVisible,
    void Function() onEarned,
  ) async {
    final closed = Completer<void>();
    void finish() {
      if (!closed.isCompleted) {
        closed.complete();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, _) => finish(),
    );
    onVisible(true);
    try {
      await ad.show(onUserEarnedReward: (_, _) => onEarned());
      await closed.future;
    } finally {
      onVisible(false);
    }
  }
}
