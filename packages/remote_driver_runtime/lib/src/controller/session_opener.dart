import 'dart:async';

import 'package:remote_core/remote_core.dart';

import '../engines/common/transport_connection_error.dart';
import '../engines/contracts/engine_operation.dart';
import '../engines/contracts/engine_session.dart';
import '../engines/contracts/engine_session_context.dart';
import '../integrations/verification_outcome.dart';
import 'active_session.dart';
import 'integration_plan.dart';
import 'integration_planner.dart';

/// Opens an authenticated session for a plan: connect, identify the TV
/// software, refine the compatibility selection (one handoff at most) and
/// run the declared verification probes.
final class SessionOpener {
  SessionOpener({
    required this.planner,
    required this.credentials,
    required this.onState,
    required this.onPairingCode,
  });

  final IntegrationPlanner planner;
  final CredentialStore credentials;
  final void Function(DeviceConnectionState state) onState;
  final void Function(Future<bool> Function(String code)? submit) onPairingCode;

  Future<ActiveSession> open(
    RemoteDevice device,
    IntegrationPlan plan,
    bool Function() current,
  ) async {
    var selected = plan;
    var session = await _connect(device, selected, current);
    var software = await _identify(session, selected);
    final refined = await planner.refine(selected, device, software);
    if (!identical(refined, selected) &&
        refined.identity != selected.identity) {
      await session.close();
      _require(current);
      session = await _connect(device, refined, current);
      software = await _identify(session, refined) ?? software;
    }
    selected = refined;
    final probes = await _probes(session, selected);
    _require(current);
    return ActiveSession(selected, session, probes, software);
  }

  Future<EngineSession> _connect(
    RemoteDevice device,
    IntegrationPlan plan,
    bool Function() current,
  ) async {
    final definition = plan.definition;
    final session = await definition.engine.open(
      EngineSessionContext(
        device: device,
        credentials: credentials,
        credentialKey:
            definition.manifest.credentialScope == CredentialScope.device
            ? device.id
            : '${definition.identity.integrationId}:${device.id}',
        connection: definition.connection,
        onState: onState,
        onPairingCode: onPairingCode,
      ),
    );
    if (!current()) {
      await session.close();
      _require(current);
    }
    return session;
  }

  Future<DeviceSoftwareInformation?> _identify(
    EngineSession session,
    IntegrationPlan plan,
  ) async {
    final mapping = plan.definition.operations(
      plan.profile,
    )[RuntimeOperations.identifySoftware];
    if (mapping == null) {
      return session.software;
    }
    try {
      final reported = await session.execute(mapping.operation, const {});
      return reported is DeviceSoftwareInformation
          ? reported
          : session.software;
    } on Object {
      // Software details are optional; failures never block connecting.
      return session.software;
    }
  }

  /// Probes start together in declaration order; each runs once.
  Future<Map<String, VerificationOutcome>> _probes(
    EngineSession session,
    IntegrationPlan plan,
  ) async {
    final table = plan.definition.operations(plan.profile);
    final probes = <String, Future<VerificationOutcome>>{};
    for (final declaration in plan.definition.capabilities) {
      final verification = declaration.verification;
      final mapping = verification == null
          ? null
          : table[verification.operation];
      if (verification == null || mapping == null) {
        continue;
      }
      probes.putIfAbsent(
        verification.operation,
        () => _probe(session, mapping.operation, verification.timeout),
      );
    }
    return {for (final entry in probes.entries) entry.key: await entry.value};
  }

  static Future<VerificationOutcome> _probe(
    EngineSession session,
    EngineOperation operation,
    Duration? timeout,
  ) async {
    try {
      final run = session.execute(operation, const {});
      final value = await (timeout == null ? run : run.timeout(timeout));
      return VerificationOutcome.success(value);
    } on Object catch (error) {
      return VerificationOutcome.failure(
        transportConnectionError(error).message,
      );
    }
  }

  static void _require(bool Function() current) {
    if (!current()) {
      throw const RemoteException('cancelled', 'Connection was cancelled.');
    }
  }
}
