import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../storage/contracts/application_storage.dart';
import '../contracts/interstitial_advertising.dart';
import '../contracts/rewarded_advertising.dart';

final class ActiveSession extends ChangeNotifier {
  ActiveSession(
    this._storage,
    this._ads, {
    InterstitialAdvertising? interstitial,
    Duration Function()? now,
  }) : _interstitial = interstitial,
       _now = now ?? _monotonicClock(),
       _interstitialWait = interstitial == null
           ? Duration.zero
           : interstitialInterval;

  static const storageKey = 'active-session.v1';
  static const extension = Duration(hours: 2);
  static const interstitialInterval = Duration(minutes: 20);
  static const warningTime = Duration(minutes: 1);
  static const checkpoint = Duration(seconds: 30);

  static Duration Function() _monotonicClock() {
    final clock = Stopwatch()..start();
    return () => clock.elapsed;
  }

  final ApplicationStorage _storage;
  final RewardedAdvertising _ads;
  final InterstitialAdvertising? _interstitial;
  final Duration Function() _now;
  Duration _balance = Duration.zero;
  Duration _interstitialWait;
  Duration? _started;
  Duration? _nextCheckpoint;
  Timer? _timer;
  Future<void> _writes = Future.value();
  String? _lastSnapshot;
  bool _foreground = false;
  bool _showingAd = false;
  bool _requesting = false;
  bool _presentingInterstitial = false;
  bool _warningShown = false;
  bool _warningSignalled = false;
  bool _disposed = false;

  Duration get remaining => _remaining(_balance);
  Duration get _untilInterstitial => _remaining(_interstitialWait);
  bool get counting => _started != null && !expired;
  bool get expired => remaining == Duration.zero;
  bool get requesting => _requesting;
  bool get canExtend =>
      remaining <= warningTime && !_requesting && !_presentingInterstitial;
  bool get warningDue =>
      _foreground &&
      !_requesting &&
      !_warningShown &&
      !expired &&
      remaining <= warningTime;
  bool get _interstitialDue =>
      _foreground &&
      expired &&
      !_showingAd &&
      !_requesting &&
      _untilInterstitial == Duration.zero;

  ValueListenable<bool> get privacyOptionsRequired =>
      _ads.privacyOptionsRequired;
  Future<void> showPrivacyOptions() => _ads.showPrivacyOptions();

  Duration _remaining(Duration balance) {
    final started = _started;
    final left = started == null ? balance : balance - (_now() - started);
    return left.isNegative ? Duration.zero : left;
  }

  Future<void> restore() async {
    try {
      final stored = await _storage.read(storageKey);
      if (stored != null && _restoreSnapshot(stored)) {
        return;
      }
    } on Exception {
      // Advertising can run without persisted preferences.
    }
    await _save();
  }

  bool _restoreSnapshot(String stored) {
    final snapshot = jsonDecode(stored);
    if (snapshot is! Map<String, dynamic> || snapshot['remainingMs'] is! int) {
      return false;
    }
    _balance = Duration(
      milliseconds: (snapshot['remainingMs'] as int).clamp(
        0,
        extension.inMilliseconds,
      ),
    );
    _warningShown = snapshot['warningShown'] == true;
    _lastSnapshot = stored;
    if (_interstitial != null) {
      _restoreInterstitialWait(snapshot['interstitialWaitMs']);
    }
    return true;
  }

  void _restoreInterstitialWait(Object? storedWait) {
    if (storedWait is! int) {
      _interstitialWait = _balance + interstitialInterval;
      return;
    }
    final maximum = (extension + interstitialInterval).inMilliseconds;
    _interstitialWait = Duration(
      milliseconds: storedWait.clamp(_balance.inMilliseconds, maximum),
    );
  }

  void setForeground(bool active) {
    if (_disposed || _foreground == active) {
      return;
    }
    _foreground = active;
    _syncAccounting();
    if (!active) {
      unawaited(_save());
      return;
    }
    if (_interstitialDue) {
      unawaited(_prepareInterstitial());
    }
  }

  void acknowledgePrompt() {
    if (!expired && remaining <= warningTime) {
      _warningShown = true;
      _schedule();
    }
  }

  Future<bool> showInterstitial({required bool Function() canPresent}) async {
    final ads = _interstitial;
    if (ads == null ||
        _disposed ||
        !_interstitialDue ||
        _presentingInterstitial ||
        !canPresent()) {
      return false;
    }
    _presentingInterstitial = true;
    var shown = false;
    try {
      await ads.show(
        canPresent: () => !_disposed && _interstitialDue && canPresent(),
        onVisible: _adVisibility,
        onShown: () {
          shown = true;
          _recordInterstitial();
        },
      );
    } on Exception {
      // A failed ad must never interrupt navigation or TV use.
    } finally {
      _finishInterstitial();
    }
    return shown;
  }

  void _finishInterstitial() {
    _presentingInterstitial = false;
    if (_disposed) {
      return;
    }
    _adVisibility(false);
    if (_interstitialDue) {
      unawaited(_prepareInterstitial());
    }
  }

  Future<void> _prepareInterstitial() async {
    try {
      await _interstitial?.prepare();
    } on Exception {
      // Retry at a later break if the SDK or network is unavailable.
    }
  }

  void _recordInterstitial() {
    if (_disposed) {
      return;
    }
    _stop();
    _interstitialWait = interstitialInterval;
    _syncAccounting();
    unawaited(_save());
  }

  Future<bool> requestExtension({required bool Function() canPresent}) async {
    if (_disposed || !_foreground || !canExtend) {
      return false;
    }
    _requesting = true;
    notifyListeners();
    var earned = false;
    var accepting = true;
    try {
      await _ads.show(
        canPresent: () => !_disposed && _foreground && canPresent(),
        onVisible: _adVisibility,
        onEarned: () {
          if (_disposed || earned || !accepting) {
            return;
          }
          earned = true;
          _grantReward();
        },
      );
      return earned;
    } on Exception {
      return earned;
    } finally {
      accepting = false;
      _requesting = false;
      if (!_disposed) {
        _showingAd = false;
        _syncAccounting();
      }
    }
  }

  void _adVisibility(bool visible) {
    if (_disposed || _showingAd == visible) {
      return;
    }
    _showingAd = visible;
    _syncAccounting();
    if (visible) {
      unawaited(_save());
    }
  }

  void _grantReward() {
    _stop();
    _balance = extension;
    if (_interstitial != null) {
      _interstitialWait = extension + interstitialInterval;
    }
    _warningShown = false;
    _warningSignalled = false;
    _syncAccounting();
    unawaited(_save());
  }

  void _syncAccounting() {
    _updateClock();
    _schedule();
    notifyListeners();
  }

  Duration get _activeTimeLeft {
    final reward = remaining;
    final interval = _untilInterstitial;
    return reward > interval ? reward : interval;
  }

  void _updateClock() {
    if (!_foreground || _showingAd || _activeTimeLeft == Duration.zero) {
      _stop();
      return;
    }
    _started ??= _now();
    _nextCheckpoint ??= _now() + checkpoint;
  }

  void _stop() {
    _balance = remaining;
    _interstitialWait = _untilInterstitial;
    _started = null;
    _nextCheckpoint = null;
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    final nextCheckpoint = _nextCheckpoint;
    if (nextCheckpoint == null) {
      return;
    }
    var delay = nextCheckpoint - _now();
    for (final deadline in [
      remaining,
      _untilInterstitial,
      if (!_warningShown && !_warningSignalled) remaining - warningTime,
    ]) {
      if (deadline > Duration.zero && deadline < delay) {
        delay = deadline;
      }
    }
    _timer = Timer(delay, _deadline);
  }

  void _deadline() {
    final ended = expired && _balance > Duration.zero;
    final intervalReached =
        _untilInterstitial == Duration.zero &&
        _interstitialWait > Duration.zero;
    final warning = warningDue && !_warningSignalled;
    if (warning) {
      _warningSignalled = true;
    }
    if (ended || intervalReached || _now() >= _nextCheckpoint!) {
      _checkpoint();
    }
    if (intervalReached && _interstitialDue) {
      unawaited(_prepareInterstitial());
    }
    if (warning || ended) {
      notifyListeners();
    }
    _schedule();
  }

  void _checkpoint() {
    _stop();
    _updateClock();
    unawaited(_save());
  }

  Future<void> _save() {
    final snapshot = jsonEncode({
      'remainingMs': remaining.inMilliseconds,
      'interstitialWaitMs': _untilInterstitial.inMilliseconds,
      'warningShown': _warningShown,
    });
    if (snapshot == _lastSnapshot) {
      return _writes;
    }
    _lastSnapshot = snapshot;
    return _writes = _writes.then((_) async {
      try {
        await _storage.write(storageKey, snapshot);
      } on Exception {
        if (_lastSnapshot == snapshot) {
          _lastSnapshot = null;
        }
      }
    });
  }

  Future<void> close() {
    if (!_disposed) {
      _disposed = true;
      _timer?.cancel();
      _stop();
      _interstitial?.dispose();
      super.dispose();
    }
    return _save();
  }
}
