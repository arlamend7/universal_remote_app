import 'package:remote_core/remote_core.dart';

final class SavedDeviceMapper {
  const SavedDeviceMapper({this.categoryForProvider});
  final DeviceCategory Function(String)? categoryForProvider;
  RemoteDevice fromJson(Object? value) {
    final map = value as Map<String, dynamic>;
    return RemoteDevice(
      id: map['id'] as String,
      name: map['name'] as String,
      providerId: map['providerId'] as String,
      manufacturer: map['manufacturer'] as String?,
      model: map['model'] as String?,
      category: _category(map),
      capabilities: _capabilities(map['capabilities']),
      stableIdentity: map['stableIdentity'] as bool,
      pairingState: PairingState.paired,
      endpoints: (map['endpoints'] as List<dynamic>)
          .cast<String>()
          .map(Uri.parse)
          .toList(),
      metadata: (map['metadata'] as Map<String, dynamic>)
          .cast<String, String>(),
    );
  }

  DeviceCategory _category(Map<String, dynamic> map) {
    final name = map['category'];
    if (name == null) {
      return categoryForProvider?.call(map['providerId'] as String) ??
          DeviceCategory.unknown;
    }
    return DeviceCategory.values
            .where((item) => item.name == name)
            .firstOrNull ??
        DeviceCategory.unknown;
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
    'endpoints': device.endpoints
        .map((endpoint) => endpoint.toString())
        .toList(),
    'metadata': device.metadata,
  };
}
