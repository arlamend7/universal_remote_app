import 'package:remote_core/remote_core.dart';

import 'integration_plan.dart';

/// Resolves, installs and records integrations for device sessions.
///
/// The runtime asks for a plan inside `connect()` before any command is
/// sent; the driver manager implements this contract.
abstract interface class IntegrationPlanner {
  /// Stage 1: a verified package and bootstrap profile for [device],
  /// installing it first when it is missing.
  Future<IntegrationPlan> prepare(
    RemoteDevice device, {
    void Function(double? progress)? onProgress,
  });

  /// Stage 2: the plan for software reported by the authenticated session.
  /// Returns [current] when nothing changes.
  Future<IntegrationPlan> refine(
    IntegrationPlan current,
    RemoteDevice device,
    DeviceSoftwareInformation? software,
  );

  /// Persists the device assignment once a session is connected.
  Future<void> remember(IntegrationPlan plan, RemoteDevice device);

  /// Called when the session using [plan] ends, so staged updates can apply.
  void release(IntegrationPlan plan);
}
