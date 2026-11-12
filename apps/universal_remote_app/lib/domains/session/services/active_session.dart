import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../storage/contracts/application_storage.dart';
import '../contracts/rewarded_advertising.dart';

final class ActiveSession extends ChangeNotifier {
  ActiveSession(this._storage, this._ads, {Duration Function()? now})
    : _now = now ?? _monotonicClock();

  static const storageKey = 'active-session.v1';
  static const extension = Duration(minutes: 30);
  static const warningTime = Duration(minutes: 1);
  static const checkpoint = Duration(seconds: 10);
  static const cooldown = Duration(minutes: 1);
  static const maximum = Duration(minutes: 60);
  static Duration Function() _monotonicClock() {
    final clock = Stopwatch()..start();
    return () => clock.elapsed;
  }

  final ApplicationStorage _storage;
  final RewardedAdvertising _ads;
  final Duration Function() _now;
  Duration _balance = extension;
  Duration? _started;
  Duration? _nextCheckpoint;
  Duration? _rewardThreshold;
  Timer? _timer;
  Future<void> _writes = Future.value();
  String? _lastSnapshot;
  bool _foreground = false;
  bool _showingAd = false;
  bool _requesting = false;
  bool _warningShown = false;
  bool _warningSignalled = false;
  bool _extensionAvailable = true;
  bool _expirationShown = false;
  bool _disposed = false;

  Duration get remaining {
    final started = _started;
    final balance = started == null ? _balance : _balance - (_now() - started);
    return balance.isNegative ? Duration.zero : balance;
  }

  bool get counting => _started != null && remaining > Duration.zero;
  bool get expired => remaining == Duration.zero;
  bool get requesting => _requesting;
  ValueListenable<bool> get privacyOptionsRequired =>
      _ads.privacyOptionsRequired;
  Future<void> showPrivacyOptions() => _ads.showPrivacyOptions();
  Duration get _extensionThreshold => _rewardThreshold ?? maximum - extension;
  bool get canExtend => !_requesting && remaining <= _extensionThreshold;
  bool get warningDue =>
      _foreground &&
      !_requesting &&
      !_warningShown &&
      !expired &&
      remaining <= warningTime;
  bool get expirationDue =>
      _foreground && !_requesting && expired && !_expirationShown;

  Future<void> restore() async {
    try {
      final stored = await _storage.read(storageKey);
      if (stored != null && _restoreSnapshot(stored)) {
        return;
      }
    } on Exception {
      // The optional session can still run if preferences are unavailable.
    }
    await _save();
  }

  bool _restoreSnapshot(String stored) {
    final snapshot = jsonDecode(stored);
    if (snapshot is! Map<String, dynamic> || snapshot['remainingMs'] is! int) {
      return false;
    }
    final ms = (snapshot['remainingMs'] as int).clamp(
      0,
      maximum.inMilliseconds,
    );
    _balance = Duration(milliseconds: ms);
    _warningShown = snapshot['warningShown'] == true;
    _lastSnapshot = stored;
    final threshold = snapshot['rewardThresholdMs'];
    if (threshold is int) {
      _rewardThreshold = Duration(
        milliseconds: threshold.clamp(0, (maximum - extension).inMilliseconds),
      );
    }
    return true;
  }

  void setForeground(bool active) {
    if (_disposed || _foreground == active) {
      return;
    }
    _foreground = active;
    _syncAccounting();
    if (!active) {
      unawaited(_save());
    }
  }

  void acknowledgePrompt() {
    if (expired) {
      _expirationShown = true;
      return;
    }
    if (remaining <= warningTime) {
      _warningShown = true;
      _schedule();
    }
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
    _balance = remaining + extension;
    _started = null;
    _nextCheckpoint = null;
    _warningShown = false;
    _warningSignalled = false;
    _expirationShown = false;
    final cooldownThreshold = _balance - cooldown;
    final capacityThreshold = maximum - extension;
    _rewardThreshold = cooldownThreshold < capacityThreshold
        ? cooldownThreshold
        : capacityThreshold;
    _syncAccounting();
    unawaited(_save());
  }

  void _syncAccounting() {
    _updateClock();
    _schedule();
    _extensionAvailable = canExtend;
    notifyListeners();
  }

  void _updateClock() {
    if (!_foreground || _showingAd || expired) {
      _stop();
      return;
    }
    _started ??= _now();
    _nextCheckpoint ??= _now() + checkpoint;
  }

  void _stop() {
    _balance = remaining;
    _started = null;
    _nextCheckpoint = null;
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!counting) {
      return;
    }
    final balance = remaining;
    final untilCheckpoint = _nextCheckpoint! - _now();
    var delay = untilCheckpoint < balance ? untilCheckpoint : balance;
    final untilWarning = balance - warningTime;
    if (!_warningShown &&
        !_warningSignalled &&
        untilWarning > Duration.zero &&
        untilWarning < delay) {
      delay = untilWarning;
    }
    final untilExtension = balance - _extensionThreshold;
    if (!_requesting &&
        untilExtension > Duration.zero &&
        untilExtension < delay) {
      delay = untilExtension;
    }
    _timer = Timer(delay, _deadline);
  }

  void _deadline() {
    final now = _now();
    if (expired) {
      _stop();
      unawaited(_save());
      notifyListeners();
      return;
    }
    if (now >= _nextCheckpoint!) {
      _nextCheckpoint = now + checkpoint;
      unawaited(_save());
    }
    final warn = warningDue && !_warningSignalled;
    if (warn) {
      _warningSignalled = true;
    }
    if (warn || canExtend != _extensionAvailable) {
      _extensionAvailable = canExtend;
      notifyListeners();
    }
    _schedule();
  }

  Future<void> _save() {
    final snapshot = jsonEncode({
      'remainingMs': remaining.inMilliseconds,
      'warningShown': _warningShown,
      'rewardThresholdMs': _rewardThreshold?.inMilliseconds,
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
      super.dispose();
    }
    return _save();
  }
}
