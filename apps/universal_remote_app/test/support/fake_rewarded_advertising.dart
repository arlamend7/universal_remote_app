import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:universal_remote_app/domains/session/contracts/rewarded_advertising.dart';

final class FakeRewardedAdvertising implements RewardedAdvertising {
  @override
  final privacyOptionsRequired = ValueNotifier(false);

  Completer<void>? _dismissed;
  void Function()? earn;
  void Function(bool)? _visibility;
  int requests = 0;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<void> show({
    required bool Function() canPresent,
    required void Function(bool) onVisible,
    required void Function() onEarned,
  }) async {
    requests++;
    if (!canPresent()) {
      return;
    }
    _dismissed = Completer<void>();
    earn = onEarned;
    _visibility = onVisible;
    onVisible(true);
    await _dismissed!.future;
  }

  void dismiss() {
    _visibility?.call(false);
    _dismissed!.complete();
  }
}
