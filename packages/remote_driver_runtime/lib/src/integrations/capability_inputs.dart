import 'package:remote_core/remote_core.dart';

import 'integration_definition.dart';
import 'operation_table.dart';
import 'verification_outcome.dart';

/// Everything the declarative capability resolver may consider.
final class CapabilityInputs {
  const CapabilityInputs({
    required this.definition,
    required this.profile,
    required this.table,
    this.facts = const {},
    this.software,
    this.model,
    this.probes = const {},
    this.unusableKinds = const {},
    this.withdrawn = const {},
  });

  final IntegrationDefinition definition;
  final CompatibilityProfile profile;
  final OperationTable table;
  final Map<String, String> facts;
  final DeviceSoftwareInformation? software;
  final String? model;

  /// Verification results keyed by probe operation ID.
  final Map<String, VerificationOutcome> probes;

  /// Engine operation kinds the session reported as unusable.
  final Set<String> unusableKinds;

  /// Capabilities withdrawn after a command failure, with the reason.
  final Map<RemoteCapability, String> withdrawn;
}
