import 'driver_integration_summary.dart';

/// One provider family and its compatibility-family integrations.
final class DriverProviderSummary {
  const DriverProviderSummary(this.providerId, this.integrations);

  final String providerId;
  final List<DriverIntegrationSummary> integrations;

  String get name => integrations.first.entry.manufacturer;
  String get platform => integrations.first.entry.platform;
  int get installed =>
      integrations.where((integration) => integration.isInstalled).length;
}
