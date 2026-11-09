import 'dart:convert';

import 'package:remote_core/remote_core.dart';

import '../../../domains/storage/contracts/application_storage.dart';
import '../../../domains/devices/repositories/device_profile_repository.dart';
import '../mappers/saved_device_mapper.dart';

final class SavedDeviceRepository implements DeviceProfileRepository {
  SavedDeviceRepository(
    this.storage, {
    this.mapper = const SavedDeviceMapper(),
  });

  static const currentKey = 'saved-devices.v2';
  final ApplicationStorage storage;
  final SavedDeviceMapper mapper;
  final _registry = const DeviceRegistry();

  @override
  Future<List<RegisteredDevice>> loadRegistered() async {
    final current = await storage.read(currentKey);
    if (current == null) {
      return [];
    }
    try {
      return _registry.validate(_readCurrent(current));
    } catch (_) {
      throw const RemoteException(
        'profiles',
        'Saved devices could not be read. Their protected data has not been overwritten.',
      );
    }
  }

  Iterable<RegisteredDevice> _readCurrent(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['version'] != 2) {
      throw const FormatException('Unsupported device storage version.');
    }
    return (json['devices'] as List).cast<Map<String, dynamic>>().map(
      _readDevice,
    );
  }

  RegisteredDevice _readDevice(Map<String, dynamic> json) => RegisteredDevice(
    id: json['id'] as String,
    name: json['name'] as String,
    category: DeviceCategory.values.byName(json['category'] as String),
    preferredProviderId: json['preferredProviderId'] as String?,
    profiles: (json['profiles'] as List).cast<Map<String, dynamic>>().map(
      (profile) => ConnectionProfile(
        mapper.fromJson(profile['configuration']),
        confirmed: profile['confirmed'] as bool,
        userAssociated: profile['userAssociated'] == true,
      ),
    ),
  );

  @override
  Future<void> saveRegistered(List<RegisteredDevice> devices) => storage.write(
    currentKey,
    jsonEncode({
      'version': 2,
      'devices': _registry.validate(devices).map(_writeDevice).toList(),
    }),
  );

  Map<String, Object?> _writeDevice(RegisteredDevice device) => {
    'id': device.id,
    'name': device.name,
    'category': device.category.name,
    'preferredProviderId': device.preferredProviderId,
    'profiles': [
      for (final profile in device.profiles)
        {
          'confirmed': profile.confirmed,
          if (profile.userAssociated) 'userAssociated': true,
          'configuration': mapper.toJson(profile.device),
        },
    ],
  };
}
