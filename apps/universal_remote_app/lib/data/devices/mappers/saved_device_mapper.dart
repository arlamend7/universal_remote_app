import 'package:remote_core/remote_core.dart';

final class SavedDeviceMapper {
  const SavedDeviceMapper();
  RemoteDevice fromJson(Object? value) {
    final map = value as Map<String, dynamic>;
    final metadata = (map['metadata'] as Map<String, dynamic>)
        .cast<String, String>();
    return RemoteDevice(
      id: map['id'] as String,
      name: map['name'] as String,
      providerId: map['providerId'] as String,
      manufacturer: map['manufacturer'] as String?,
      model: map['model'] as String?,
      category: DeviceCategory.values.byName(map['category'] as String),
      capabilities: _capabilities(map['capabilities']),
      stableIdentity: map['stableIdentity'] as bool,
      pairingState: PairingState.values.byName(map['pairingState'] as String),
      endpoints: (map['endpoints'] as List<dynamic>)
          .cast<String>()
          .map(Uri.parse)
          .toList(),
      metadata: metadata,
      softwareInformation:
          DeviceSoftwareInformation.fromJson(map['softwareInformation']) ??
          DeviceSoftwareInformation.fromLegacyMetadata(metadata),
    );
  }

  Set<RemoteCapability> _capabilities(Object? value) {
    if (value is! List) {
      return {};
    }
    return RemoteCapability.values
        .where((item) => value.contains(item.name))
        .toSet();
  }

  Map<String, Object?> toJson(RemoteDevice device) => {
    'id': device.id,
    'name': device.name,
    'providerId': device.providerId,
    'manufacturer': device.manufacturer,
    'model': device.model,
    'category': device.category.name,
    'capabilities': device.capabilities.map((item) => item.name).toList(),
    'stableIdentity': device.stableIdentity,
    'pairingState': device.pairingState.name,
    'endpoints': device.endpoints
        .map((endpoint) => endpoint.toString())
        .toList(),
    'metadata': device.metadata,
    if (device.softwareInformation case final information?)
      'softwareInformation': information.toJson(),
  };
}
