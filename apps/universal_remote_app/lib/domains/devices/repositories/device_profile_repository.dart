import 'package:remote_core/remote_core.dart';

abstract interface class DeviceProfileRepository {
  Future<List<RegisteredDevice>> loadRegistered();
  Future<void> saveRegistered(List<RegisteredDevice> devices);
}
