import 'package:remote_core/remote_core.dart';

import 'engine_operation.dart';

/// An engine that can wake a device in network standby without a session.
abstract interface class OfflineWakeEngine {
  Future<void> wakeOffline(RemoteDevice device, EngineOperation operation);
}
