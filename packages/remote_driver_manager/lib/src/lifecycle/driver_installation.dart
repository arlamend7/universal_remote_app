import 'package:remote_core/remote_core.dart';

final class DriverInstallation {
  const DriverInstallation({
    required this.id,
    required this.active,
    this.previous,
    this.enabled = true,
    this.retained = const {},
  });

  factory DriverInstallation.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final active = json['active'];
    final previous = json['previous'];
    final enabled = json['enabled'];
    final retained = json['retained'] ?? const <Object?>[];
    if (retained is! List<Object?> ||
        retained.length > 256 ||
        retained.any((value) => value is! String)) {
      throw const FormatException('Invalid retained driver versions.');
    }
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
      retained: Set.unmodifiable(
        retained.cast<String>().map(DriverVersion.parse),
      ),
    );
  }

  final String id;
  final DriverVersion active;
  final DriverVersion? previous;
  final bool enabled;
  final Set<DriverVersion> retained;

  Set<DriverVersion> get versions => {
    active,
    if (previous case final version?) version,
    ...retained,
  };

  Map<String, Object?> toJson() => {
    'id': id,
    'active': active.toString(),
    if (previous != null) 'previous': previous.toString(),
    'enabled': enabled,
    if (retained.isNotEmpty)
      'retained': retained.map((version) => '$version').toList(),
  };
}
