import 'package:remote_core/remote_core.dart';

import 'manual_setup_rules.dart';

/// `device.json`: manual setup, connection policy and offline wake.
final class DeviceRules {
  DeviceRules._(this.setup, this.policy, this.wake);

  factory DeviceRules.fromJson(Map<String, Object?> json) {
    IntegrationJson.keys(json, const {'setup', 'policy', 'wake'});
    final policy = json['policy'];
    final wake = json['wake'];
    if (policy != null) {
      _policy(IntegrationJson.object(policy, 'policy'));
    }
    if (wake != null) {
      _wake(IntegrationJson.object(wake, 'wake'));
    }
    return DeviceRules._(
      json['setup'] == null ? null : ManualSetupRules.fromJson(json['setup']),
      policy as Map<String, Object?>?,
      wake as Map<String, Object?>?,
    );
  }

  final ManualSetupRules? setup;
  final Map<String, Object?>? policy;
  final Map<String, Object?>? wake;

  static void _policy(Map<String, Object?> json) {
    IntegrationJson.keys(json, const {
      'sameConnection',
      'retryAfterWake',
      'certificateReview',
      'mergeDiscovered',
    });
    IntegrationJson.labels(json, 'sameConnection');
    IntegrationJson.labels(json, 'retryAfterWake');
    final merge = json['mergeDiscovered'];
    if (merge != null &&
        !const {'replace-host', 'discovered-endpoints'}.contains(merge)) {
      throw const FormatException('Unknown discovered-device merge rule.');
    }
    final review = json['certificateReview'];
    if (review != null) {
      IntegrationJson.keys(
        IntegrationJson.object(review, 'certificateReview'),
        const {'errorCode', 'scheme'},
        required: const {'errorCode', 'scheme'},
      );
    }
  }

  static void _wake(Map<String, Object?> json) {
    IntegrationJson.keys(
      json,
      const {'kind', 'mapping', 'requiresCapability', 'message', 'fallback'},
      required: const {'kind'},
    );
    if (!const {'wake-on-lan', 'engine'}.contains(json['kind'])) {
      throw const FormatException('Unknown wake rule.');
    }
    if (json['requiresCapability'] != null) {
      parseRemoteCapability(json['requiresCapability']);
    }
    if (json['fallback'] != null &&
        (json['kind'] != 'engine' || json['fallback'] != 'wake-on-lan')) {
      throw const FormatException('Unknown wake fallback.');
    }
  }
}
