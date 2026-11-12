import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/integrations.dart';

import '../catalog/catalog_integration.dart';

/// Discovery and device rules one integration contributes to its provider.
final class ProviderRuleSource {
  const ProviderRuleSource({
    required this.identity,
    required this.engine,
    this.priority = 0,
    this.development = false,
    this.discovery,
    this.device,
  });

  factory ProviderRuleSource.catalog(CatalogIntegration entry) =>
      ProviderRuleSource(
        identity: entry.identity,
        engine: entry.engine,
        priority: entry.priority,
        development: entry.development,
        discovery: entry.discovery,
        device: entry.device,
      );

  factory ProviderRuleSource.definition(
    IntegrationDefinition definition, {
    bool development = false,
  }) => ProviderRuleSource(
    identity: definition.identity,
    engine: definition.manifest.engine,
    priority: definition.manifest.priority,
    development: development,
    discovery: definition.document('discovery.json'),
    device: definition.document('device.json'),
  );

  final IntegrationIdentity identity;
  final String engine;
  final int priority;
  final bool development;
  final Map<String, Object?>? discovery;
  final Map<String, Object?>? device;
}
