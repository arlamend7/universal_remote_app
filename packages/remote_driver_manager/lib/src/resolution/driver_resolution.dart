import 'driver_match.dart';
import 'driver_rejection.dart';

final class DriverResolution {
  DriverResolution({
    this.selected,
    required Iterable<DriverMatch> alternatives,
    required Iterable<DriverRejection> rejected,
  }) : alternatives = List.unmodifiable(alternatives),
       rejected = List.unmodifiable(rejected);

  final DriverMatch? selected;
  final List<DriverMatch> alternatives;
  final List<DriverRejection> rejected;

  bool get requiresSelection => selected == null && alternatives.length > 1;
}
