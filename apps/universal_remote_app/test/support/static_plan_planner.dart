import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';

/// Serves one compiled integration plan to generic controllers in tests.
final class StaticPlanPlanner implements IntegrationPlanner {
  StaticPlanPlanner(this.plan);

  final IntegrationPlan plan;

  @override
  Future<IntegrationPlan> prepare(
    RemoteDevice device, {
    void Function(double? progress)? onProgress,
  }) async => plan;

  @override
  Future<IntegrationPlan> refine(
    IntegrationPlan current,
    RemoteDevice device,
    DeviceSoftwareInformation? software,
  ) async => current;

  @override
  Future<void> remember(IntegrationPlan plan, RemoteDevice device) async {}

  @override
  void release(IntegrationPlan plan) {}
}
