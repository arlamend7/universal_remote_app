import '../catalog/integration_catalog.dart';
import 'integration_metadata_keys.dart';

/// Rewrites version-based driver metadata on a saved device.
///
/// Device IDs, endpoints, credentials, certificate pins and every other key
/// are untouched. A retired family maps to an integration only when exactly
/// one published integration `replaces` it; otherwise the device is resolved
/// again from its software evidence on the next connection.
Map<String, String> migrateLegacyDeviceMetadata(
  Map<String, String> metadata, {
  IntegrationCatalog? catalog,
}) {
  if (!metadata.keys.any(IntegrationMetadataKeys.legacy.contains)) {
    return metadata;
  }
  final family = metadata['managedDriverId'];
  final migrated = {...metadata}
    ..removeWhere((key, _) => IntegrationMetadataKeys.legacy.contains(key));
  final successors = family == null || catalog == null
      ? const <String>[]
      : [
          for (final integration in catalog.integrations)
            if (integration.replaces.contains(family)) integration.id,
        ];
  if (successors.length == 1 &&
      !migrated.containsKey(IntegrationMetadataKeys.integrationId)) {
    migrated[IntegrationMetadataKeys.integrationId] = successors.single;
  }
  return migrated;
}
