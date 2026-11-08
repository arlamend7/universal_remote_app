import 'dart:convert';

import 'package:remote_core/remote_core.dart';

import '../../../domains/storage/contracts/application_storage.dart';
import '../mappers/saved_device_mapper.dart';
import '../../../domains/devices/repositories/device_profile_repository.dart';

final class SavedDeviceRepository implements DeviceProfileRepository {
  SavedDeviceRepository(
    this.storage, {
    this.mapper = const SavedDeviceMapper(),
  });
  final ApplicationStorage storage;
  final SavedDeviceMapper mapper;
  @override
  Future<List<RemoteDevice>> load() async {
    final raw = await storage.read('saved-devices.v1');
    if (raw == null) {
      return [];
    }
    try {
      return (jsonDecode(raw) as List<dynamic>).map(mapper.fromJson).toList();
    } catch (_) {
      throw const RemoteException(
        'profiles',
        'Saved devices could not be read. Their protected data has not been overwritten.',
      );
    }
  }

  @override
  Future<void> save(List<RemoteDevice> devices) => storage.write(
    'saved-devices.v1',
    jsonEncode(devices.map(mapper.toJson).toList()),
  );
}
