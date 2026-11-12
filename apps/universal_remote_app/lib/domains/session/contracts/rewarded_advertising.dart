import 'package:flutter/foundation.dart';

abstract interface class RewardedAdvertising {
  ValueListenable<bool> get privacyOptionsRequired;
  Future<void> showPrivacyOptions();

  /// Calls [onEarned] only on SDK confirmation. Resolves when the ad closes.
  Future<void> show({
    required bool Function() canPresent,
    required void Function(bool) onVisible,
    required void Function() onEarned,
  });
}
