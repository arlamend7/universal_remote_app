import 'package:remote_core/remote_core.dart';

import 'driver_rejection_reason.dart';

final class DriverRejection {
  DriverRejection(
    this.identity,
    this.reason, {
    Iterable<DriverOperation> missingOperations = const [],
  }) : missingOperations = Set.unmodifiable(missingOperations);

  final DriverIdentity identity;
  final DriverRejectionReason reason;
  final Set<DriverOperation> missingOperations;
}
