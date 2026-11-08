import 'package:flutter/services.dart';

/// Short haptic and system-sound cues so controls feel physical.
///
/// Every cue is skipped while [enabled] is false. Platforms without a haptic
/// engine or click sound ignore the calls silently.
abstract final class RemoteFeedback {
  static bool enabled = true;

  /// A button press.
  static void tap() {
    if (!enabled) {
      return;
    }
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  /// A repeating step while a button is held down.
  static void tick() {
    if (!enabled) {
      return;
    }
    HapticFeedback.lightImpact();
  }

  /// A gesture that settles, such as releasing a slider or tapping the touchpad.
  static void commit() {
    if (!enabled) {
      return;
    }
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// A command the device rejected.
  static void failure() {
    if (!enabled) {
      return;
    }
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }
}
