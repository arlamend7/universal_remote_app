import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domains/session/contracts/interstitial_advertising.dart';
import 'admob_consent.dart';

final class AdMobInterstitialAdvertising implements InterstitialAdvertising {
  AdMobInterstitialAdvertising(this._unitId, this._consent);

  final String _unitId;
  final AdMobConsent _consent;
  final _clock = Stopwatch()..start();
  InterstitialAd? _ready;
  Duration? _validUntil;
  int? _consentRevision;
  bool _loading = false;
  bool _disposed = false;

  @override
  Future<void> prepare() async {
    if (_disposed || _loading) {
      return;
    }
    _discardStaleAd();
    if (_ready != null) {
      return;
    }
    _loading = true;
    try {
      if (!await _consent.canLoad() || _disposed) {
        return;
      }
      await _consent.initialize();
      if (!_disposed) {
        await _load();
      }
    } finally {
      _loading = false;
    }
  }

  Future<void> _load() async {
    final loaded = Completer<void>();
    final revision = _consent.revision;
    var waiting = true;
    try {
      await InterstitialAd.load(
        adUnitId: _unitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _cacheAd(ad, revision, waiting: waiting);
            loaded.complete();
          },
          onAdFailedToLoad: (_) => loaded.complete(),
        ),
      );
      await loaded.future.timeout(const Duration(seconds: 30));
    } finally {
      waiting = false;
    }
  }

  void _cacheAd(InterstitialAd ad, int revision, {required bool waiting}) {
    if (!waiting || _disposed || revision != _consent.revision) {
      unawaited(ad.dispose());
      return;
    }
    _ready = ad;
    _consentRevision = revision;
    _validUntil = _clock.elapsed + const Duration(minutes: 45);
  }

  void _discardStaleAd() {
    final ad = _ready;
    if (ad == null ||
        (_consentRevision == _consent.revision &&
            _clock.elapsed < _validUntil!)) {
      return;
    }
    _ready = null;
    unawaited(ad.dispose());
  }

  @override
  Future<void> show({
    required bool Function() canPresent,
    required void Function(bool) onVisible,
    required void Function() onShown,
  }) async {
    _discardStaleAd();
    final ad = _ready;
    if (ad == null || !canPresent()) {
      return;
    }
    _ready = null;
    try {
      if (await _consent.canPresent() &&
          !_disposed &&
          _consentRevision == _consent.revision &&
          canPresent()) {
        await _show(ad, onVisible, onShown);
      }
    } finally {
      await ad.dispose();
    }
  }

  Future<void> _show(
    InterstitialAd ad,
    void Function(bool) onVisible,
    void Function() onShown,
  ) async {
    final closed = Completer<void>();
    void finish() {
      if (!closed.isCompleted) {
        closed.complete();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => onShown(),
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, _) => finish(),
    );
    onVisible(true);
    try {
      await ad.show();
      await closed.future;
    } finally {
      onVisible(false);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    final ad = _ready;
    _ready = null;
    if (ad != null) {
      unawaited(ad.dispose());
    }
  }
}
