import 'package:remote_core/remote_core.dart';

import 'capability_inputs.dart';
import 'resolved_capability.dart';
import 'verification_outcome.dart';

/// Resolves capability evidence purely from integration declarations.
///
/// There is no central capability table: each integration lists the
/// operation sets that implement a capability, and the runtime only checks
/// that one of them is executable and that its declared conditions,
/// restrictions and verification hold.
abstract final class CapabilityResolver {
  static const _profileReason =
      'Disabled by the TV software compatibility profile.';
  static const _withdrawnReason =
      'The TV rejected or disconnected this control.';

  static Map<RemoteCapability, ResolvedCapability> resolve(
    CapabilityInputs inputs,
  ) => {
    for (final declaration in inputs.definition.capabilities)
      if (_resolve(declaration, inputs) case final resolved?)
        declaration.capability: resolved,
  };

  static ResolvedCapability? _resolve(
    CapabilityDeclaration declaration,
    CapabilityInputs inputs,
  ) {
    final capability = declaration.capability;
    if (inputs.profile.disabledCapabilities.contains(capability)) {
      return _evidence(
        capability,
        CapabilityAvailability.conditional,
        source: CapabilitySource.profile,
        reason: _profileReason,
      );
    }
    final withdrawn = inputs.withdrawn[capability];
    if (withdrawn != null) {
      return _evidence(
        capability,
        CapabilityAvailability.unavailable,
        reason: withdrawn,
      );
    }
    final operations = declaration.select(
      (operation) => _executable(operation, inputs),
    );
    if (operations == null) {
      return _unexecutable(declaration, inputs);
    }
    return _conditions(declaration, inputs, operations);
  }

  static ResolvedCapability? _unexecutable(
    CapabilityDeclaration declaration,
    CapabilityInputs inputs,
  ) {
    final mapped = declaration.select(inputs.table.has);
    if (mapped == null) {
      return null;
    }
    return _evidence(
      declaration.capability,
      CapabilityAvailability.unavailable,
      reason: _withdrawnReason,
    );
  }

  static ResolvedCapability? _conditions(
    CapabilityDeclaration declaration,
    CapabilityInputs inputs,
    List<String> operations,
  ) {
    final results = [
      for (final condition in declaration.conditions)
        condition.evaluate(inputs.facts),
    ];
    if (results.contains(false)) {
      return null;
    }
    if (results.contains(null)) {
      return _evidence(
        declaration.capability,
        CapabilityAvailability.conditional,
        reason: declaration.reason ?? 'Waiting for the TV to report support.',
      );
    }
    return _restrictions(declaration, inputs, operations);
  }

  static ResolvedCapability _restrictions(
    CapabilityDeclaration declaration,
    CapabilityInputs inputs,
    List<String> operations,
  ) {
    final software = inputs.software;
    final match =
        declaration.restrictions?.match(
          os: software?.operatingSystemVersion,
          firmware: software?.firmwareVersion,
          model: inputs.model ?? software?.model,
        ) ??
        VersionMatch.matches;
    if (match != VersionMatch.matches) {
      return _evidence(
        declaration.capability,
        CapabilityAvailability.conditional,
        source: CapabilitySource.profile,
        reason: match == VersionMatch.unknown
            ? 'This TV has not reported the software this control needs.'
            : 'Not supported by this TV software or model.',
      );
    }
    return _verified(declaration, inputs, operations);
  }

  static ResolvedCapability _verified(
    CapabilityDeclaration declaration,
    CapabilityInputs inputs,
    List<String> operations,
  ) {
    final verification = declaration.verification;
    if (verification == null) {
      return _evidence(
        declaration.capability,
        declaration.availability,
        operations: operations,
        reason: declaration.reason,
      );
    }
    final outcome = inputs.probes[verification.operation];
    final failure = _failure(verification, outcome, inputs.facts);
    if (failure != null) {
      return _evidence(
        declaration.capability,
        outcome == null
            ? CapabilityAvailability.conditional
            : CapabilityAvailability.unavailable,
        reason: failure,
      );
    }
    return _evidence(
      declaration.capability,
      verification.availability,
      operations: operations,
    );
  }

  static String? _failure(
    CapabilityVerification verification,
    VerificationOutcome? outcome,
    Map<String, String> facts,
  ) {
    if (outcome == null) {
      return 'This control has not been verified yet.';
    }
    if (!outcome.ok) {
      return outcome.reason ?? 'The TV did not confirm this control.';
    }
    return switch (verification.expectation) {
      VerificationExpectation.nonEmpty =>
        outcome.value is List && (outcome.value! as List).isNotEmpty
            ? null
            : 'The TV returned no entries.',
      VerificationExpectation.contains =>
        facts[verification.fact] == verification.value
            ? null
            : 'The TV did not report this control.',
      VerificationExpectation.succeeds => null,
    };
  }

  static bool _executable(String operation, CapabilityInputs inputs) {
    final mapping = inputs.table[operation];
    return mapping != null && !inputs.unusableKinds.contains(mapping.kind);
  }

  static ResolvedCapability _evidence(
    RemoteCapability capability,
    CapabilityAvailability availability, {
    CapabilitySource source = CapabilitySource.driver,
    String? reason,
    List<String> operations = const [],
  }) => ResolvedCapability(
    CapabilityEvidence(capability, source, availability, reason: reason),
    operations,
  );
}
