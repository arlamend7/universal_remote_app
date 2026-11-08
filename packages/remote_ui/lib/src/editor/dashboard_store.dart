import 'package:remote_core/remote_core.dart';

import '../layout/models/grid_layout.dart';

abstract interface class DashboardStore {
  GridLayout? forDevice(RemoteDevice device);
  Future<void> save(RemoteDevice device, GridLayout layout);
}
