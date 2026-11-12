import 'package:remote_core/remote_core.dart';

/// The integration profile last selected for one saved device.
final class DeviceAssignment {
  const DeviceAssignment({required this.profileId, required this.assignedAt});

  factory DeviceAssignment.fromJson(Object? value) {
    final json = IntegrationJson.object(value, 'assignment');
    IntegrationJson.keys(
      json,
      const {'profileId', 'assignedAt'},
      required: const {'profileId', 'assignedAt'},
    );
    return DeviceAssignment(
      profileId: IntegrationJson.identifier(json, 'profileId'),
      assignedAt: IntegrationJson.timestamp(json['assignedAt'], 'assignedAt'),
    );
  }

  final String profileId;
  final DateTime assignedAt;

  Map<String, Object?> toJson() => {
    'profileId': profileId,
    'assignedAt': IntegrationJson.formatTimestamp(assignedAt),
  };
}
