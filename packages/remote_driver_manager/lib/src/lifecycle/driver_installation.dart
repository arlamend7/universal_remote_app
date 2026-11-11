import 'package:remote_core/remote_core.dart';

final class DriverInstallation {
  const DriverInstallation({
    required this.id,
    required this.active,
    this.previous,
    this.enabled = true,
  });

  factory DriverInstallation.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final active = json['active'];
    final previous = json['previous'];
    final enabled = json['enabled'];
    if (id is! String ||
        active is! String ||
        enabled is! bool ||
        (previous != null && previous is! String)) {
      throw const FormatException('Invalid driver installation record.');
    }
    final version = DriverVersion.parse(active);
    DriverIdentity(id: id, providerId: id, version: version);
    return DriverInstallation(
      id: id,
      active: version,
      previous: previous == null
          ? null
          : DriverVersion.parse(previous as String),
      enabled: enabled,
    );
  }

  final String id;
  final DriverVersion active;
  final DriverVersion? previous;
  final bool enabled;

  Map<String, Object?> toJson() => {
    'id': id,
    'active': active.toString(),
    if (previous != null) 'previous': previous.toString(),
    'enabled': enabled,
  };
}
