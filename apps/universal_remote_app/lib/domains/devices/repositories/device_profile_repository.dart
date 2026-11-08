import 'package:remote_core/remote_core.dart';

abstract interface class DeviceProfileRepository {
  Future<List<RemoteDevice>> load();
  Future<void> save(List<RemoteDevice> devices);
}
