import 'package:remote_core/remote_core.dart';

/// Created by the host for the selected profile. Driver data has no access
/// to the storage key or to other credential operations.
final class DriverCredentialScope {
  DriverCredentialScope(this._store, String driverId, String deviceId)
    : _key =
          'driver:${driverId.length}:$driverId:${deviceId.length}:$deviceId' {
    if (driverId.isEmpty || deviceId.isEmpty) {
      throw ArgumentError('A driver and device identity are required.');
    }
  }

  final CredentialStore _store;
  final String _key;

  Future<String?> read() => _store.read(_key);

  Future<void> write(String token) {
    if (token.isEmpty || token.length > 4096) {
      throw const RemoteException('driverPairing', 'Invalid pairing token.');
    }
    return _store.write(_key, token);
  }
}
