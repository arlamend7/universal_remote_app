import 'driver_operation.dart';
import 'driver_version.dart';

/// Runtime compatibility uses a minimum and an optional exclusive upper bound.
final class DriverRuntimeRequirements {
  DriverRuntimeRequirements({
    required this.minimum,
    this.before,
    required Iterable<DriverOperation> operations,
  }) : operations = Set.unmodifiable(operations) {
    final upper = before;
    if (upper != null && minimum.compareTo(upper) >= 0) {
      throw const FormatException('Invalid runtime version range.');
    }
  }

  factory DriverRuntimeRequirements.parse(
    String constraint,
    Iterable<DriverOperation> operations,
  ) {
    final match = _format.firstMatch(constraint);
    if (match == null || match.end != constraint.length) {
      throw const FormatException('Invalid runtime version constraint.');
    }
    final upper = match[2];
    return DriverRuntimeRequirements(
      minimum: DriverVersion.parse(match[1]!),
      before: upper == null ? null : DriverVersion.parse(upper),
      operations: operations,
    );
  }

  static final _format = RegExp(r'^>=([0-9.]+)(?: <([0-9.]+))?$');

  final DriverVersion minimum;
  final DriverVersion? before;
  final Set<DriverOperation> operations;

  String get constraint => '>=$minimum${before == null ? '' : ' <$before'}';
}
