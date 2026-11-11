import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import 'driver_candidate.dart';
import 'driver_compatibility_resolver.dart';
import 'driver_match.dart';
import 'driver_rejection.dart';
import 'driver_rejection_reason.dart';
import 'driver_resolution.dart';
import 'driver_version_resolver.dart';

final class DriverResolver {
  DriverResolver({
    required this.runtimeVersion,
    required Iterable<DriverOperation> operations,
    DriverCompatibilityResolver? compatibility,
  }) : operations = Set.unmodifiable(operations),
       _compatibility = compatibility ?? DriverCompatibilityResolver();

  final DriverVersion runtimeVersion;
  final Set<DriverOperation> operations;
  final DriverCompatibilityResolver _compatibility;

  DriverResolution resolve(
    DriverDeviceEvidence device,
    Iterable<DriverCandidate> candidates, {
    bool preferInstalled = true,
  }) {
    final families = <String, DriverMatch>{};
    final rejected = <DriverRejection>[];
    for (final candidate in candidates) {
      final rejection = _rejection(candidate, device);
      if (rejection != null) {
        rejected.add(rejection);
        continue;
      }
      final match = _compatibility.resolve(candidate, device);
      if (match == null) {
        rejected.add(
          DriverRejection(
            candidate.identity,
            DriverRejectionReason.deviceCompatibility,
          ),
        );
        continue;
      }
      final id = candidate.identity.id;
      final current = families[id];
      if (current == null || _prefer(match, current, preferInstalled) > 0) {
        families[id] = match;
      }
    }
    final matches = families.values.toList()
      ..sort((a, b) => _orderFamilies(a, b, preferInstalled));
    final first = matches.firstOrNull;
    final ambiguous =
        matches.length > 1 && _rank(first!, matches[1], preferInstalled) == 0;
    return DriverResolution(
      selected: ambiguous ? null : first,
      alternatives: ambiguous ? matches : matches.skip(1),
      rejected: rejected,
    );
  }

  DriverRejection? _rejection(
    DriverCandidate candidate,
    DriverDeviceEvidence device,
  ) {
    final manifest = candidate.manifest;
    if (device.providerId != candidate.identity.providerId) {
      return DriverRejection(
        candidate.identity,
        DriverRejectionReason.providerMismatch,
      );
    }
    final manufacturer = device.manufacturer;
    if (manufacturer != null &&
        manufacturer.toLowerCase() != manifest.manufacturer.toLowerCase()) {
      return DriverRejection(
        candidate.identity,
        DriverRejectionReason.manufacturerMismatch,
      );
    }
    if (!DriverVersionResolver.supports(manifest.runtime, runtimeVersion)) {
      return DriverRejection(
        candidate.identity,
        DriverRejectionReason.runtimeVersion,
      );
    }
    final missing = manifest.runtime.operations.difference(operations);
    if (missing.isEmpty) {
      return null;
    }
    return DriverRejection(
      candidate.identity,
      DriverRejectionReason.missingOperations,
      missingOperations: missing,
    );
  }

  static int _orderFamilies(
    DriverMatch a,
    DriverMatch b,
    bool preferInstalled,
  ) {
    final priority = _rank(b, a, preferInstalled);
    return priority == 0
        ? a.candidate.identity.id.compareTo(b.candidate.identity.id)
        : priority;
  }

  static int _prefer(DriverMatch a, DriverMatch b, bool preferInstalled) {
    final priority = _rank(a, b, preferInstalled);
    return priority == 0
        ? DriverVersionResolver.preferredRelease(a, b)
        : priority;
  }

  static int _rank(DriverMatch a, DriverMatch b, bool preferInstalled) {
    if (preferInstalled && a.needsInstallation != b.needsInstallation) {
      return a.needsInstallation ? -1 : 1;
    }
    return a.compareEvidence(b);
  }
}
