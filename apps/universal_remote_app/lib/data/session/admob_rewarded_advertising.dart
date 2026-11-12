import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domains/session/contracts/rewarded_advertising.dart';

final class AdMobRewardedAdvertising implements RewardedAdvertising {
  AdMobRewardedAdvertising(this._unitId);

  final String _unitId;
  bool _initialized = false;
  bool _consentRefreshed = false;

  static AdMobRewardedAdvertising? configured() {
    const android = String.fromEnvironment('ADMOB_ANDROID_REWARDED_AD_UNIT_ID');
    const ios = String.fromEnvironment('ADMOB_IOS_REWARDED_AD_UNIT_ID');
    final unit = Platform.isAndroid ? android : (Platform.isIOS ? ios : '');
    return unit.isEmpty ? null : AdMobRewardedAdvertising(unit);
  }

  @override
  final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier(false);

  @override
  Future<void> showPrivacyOptions() async {
    if (!privacyOptionsRequired.value) {
      return;
    }
    await ConsentForm.showPrivacyOptionsForm((_) {});
  }

  @override
  Future<void> show({
    required bool Function() canPresent,
    required void Function(bool) onVisible,
    required void Function() onEarned,
  }) async {
    if (!await _allowsAds(canPresent) || !canPresent()) {
      return;
    }
    if (!_initialized) {
      await MobileAds.instance.initialize();
      _initialized = true;
    }
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

  Future<bool> _allowsAds(bool Function() canPresent) async {
    final consent = ConsentInformation.instance;
    if (!_consentRefreshed) {
      final updated = await _refreshConsent(consent);
      if (updated && canPresent()) {
        await ConsentForm.loadAndShowConsentFormIfRequired(
          (error) => _consentRefreshed = error == null,
        );
      }
    }
    privacyOptionsRequired.value =
        await consent.getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
    return consent.canRequestAds();
  }

  Future<bool> _refreshConsent(ConsentInformation consent) {
    final updated = Completer<bool>();
    consent.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => updated.complete(true),
      (_) => updated.complete(false),
    );
    return updated.future;
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
