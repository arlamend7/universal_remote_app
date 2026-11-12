import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/integrations.dart';

/// Serves fixed plans and records the planner calls a controller makes.
final class StaticIntegrationPlanner implements IntegrationPlanner {
  StaticIntegrationPlanner(this.plan, {this.refined});

  final IntegrationPlan plan;
  final IntegrationPlan? refined;
  final calls = <String>[];

  @override
  Future<IntegrationPlan> prepare(
    RemoteDevice device, {
    void Function(double? progress)? onProgress,
  }) async {
    calls.add('prepare');
    return plan;
  }

  @override
  Future<IntegrationPlan> refine(
    IntegrationPlan current,
    RemoteDevice device,
    DeviceSoftwareInformation? software,
  ) async {
    calls.add('refine:${software?.operatingSystemVersion}');
    return refined ?? current;
  }

  @override
  Future<void> remember(IntegrationPlan plan, RemoteDevice device) async =>
      calls.add('remember:${plan.identity.integrationId}:${plan.profile.id}');

  @override
  void release(IntegrationPlan plan) => calls.add('release');
}
