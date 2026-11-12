import 'package:remote_core/remote_core.dart';

import '../engines/contracts/engine_session.dart';
import '../integrations/capability_inputs.dart';
import '../integrations/capability_resolver.dart';
import '../integrations/operation_table.dart';
import '../integrations/resolved_capability.dart';
import '../integrations/verification_outcome.dart';
import 'integration_plan.dart';
import 'operation_gate.dart';

/// One connected engine session with its resolved capabilities.
final class ActiveSession {
  ActiveSession(this.plan, this.session, this.probes, this.software)
    : table = plan.definition.operations(plan.profile);

  final IntegrationPlan plan;
  final EngineSession session;
  final OperationTable table;
  final Map<String, VerificationOutcome> probes;
  final DeviceSoftwareInformation? software;
  final withdrawn = <RemoteCapability, String>{};
  final unusableKinds = <String>{};
  late Map<RemoteCapability, ResolvedCapability> resolved = resolve();

  OperationGate get gate => OperationGate(plan.definition, table, resolved);

  Map<RemoteCapability, ResolvedCapability> resolve({String? model}) =>
      resolved = CapabilityResolver.resolve(
        CapabilityInputs(
          definition: plan.definition,
          profile: plan.profile,
          table: table,
          facts: session.facts,
          software: software,
          model: model,
          probes: probes,
          unusableKinds: unusableKinds,
          withdrawn: withdrawn,
        ),
      );
}
