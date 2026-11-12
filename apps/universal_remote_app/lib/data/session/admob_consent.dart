import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

final class AdMobConsent {
  final privacyOptionsRequired = ValueNotifier(false);
  Future<bool>? _refreshing;
  Future<InitializationStatus>? _initializing;
  bool _consentFormHandled = false;
  int revision = 0;

  Future<bool> canLoad({bool Function()? canPresentConsent}) async {
    final consent = ConsentInformation.instance;
    final updated = await (_refreshing ??= _refresh(consent));
    if (!updated) {
      _refreshing = null;
    }
    if (updated && !_consentFormHandled && canPresentConsent?.call() == true) {
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        _consentFormHandled = error == null;
        revision++;
      });
    }
    privacyOptionsRequired.value =
        await consent.getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
    return consent.canRequestAds();
  }

  Future<bool> canPresent() => ConsentInformation.instance.canRequestAds();

  Future<void> initialize() async {
    try {
      await (_initializing ??= MobileAds.instance.initialize());
    } on Exception {
      _initializing = null;
      rethrow;
    }
  }

  Future<void> showPrivacyOptions() async {
    if (!privacyOptionsRequired.value) {
      return;
    }
    await ConsentForm.showPrivacyOptionsForm((_) => revision++);
  }

  Future<bool> _refresh(ConsentInformation consent) {
    final updated = Completer<bool>();
    consent.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => updated.complete(true),
      (_) => updated.complete(false),
    );
    return updated.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => false,
    );
  }
}
