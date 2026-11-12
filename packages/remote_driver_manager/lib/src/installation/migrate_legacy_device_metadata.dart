import 'package:remote_core/remote_core.dart';

import '../catalog/integration_catalog.dart';

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
  if (!metadata.keys.any(_legacy.contains)) {
    return metadata;
  }
  final family = metadata['managedDriverId'];
  final migrated = {...metadata}
    ..removeWhere((key, _) => _legacy.contains(key));
  final successors = family == null || catalog == null
      ? const <String>[]
      : [
          for (final integration in catalog.integrations)
            if (integration.replaces.contains(family)) integration.id,
        ];
  if (successors.length == 1 &&
      !migrated.containsKey(DeviceMetadataKeys.integrationId)) {
    migrated[DeviceMetadataKeys.integrationId] = successors.single;
  }
  return migrated;
}

const _legacy = {
  'managedDriverId',
  'managedDriverVersion',
  'managedDriverProfile',
  'managedDriverProfileVersion',
  'managedDriverPinnedVersion',
};
