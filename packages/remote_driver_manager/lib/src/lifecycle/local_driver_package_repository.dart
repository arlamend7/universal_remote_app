import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';

import 'driver_package.dart';
import 'driver_package_repository.dart';

/// The application must explicitly enable this source in development builds.
final class LocalDriverPackageRepository implements DriverPackageRepository {
  const LocalDriverPackageRepository._(this.package);

  final DriverPackage package;

  static Future<LocalDriverPackageRepository> open(
    Directory directory, {
    required bool enabled,
  }) async {
    final files = await LocalDriverSource(enabled: enabled).files(directory);
    return LocalDriverPackageRepository._(DriverPackage(files));
  }

  @override
  Future<DriverPackage> fetch(DriverIdentity identity) async {
    final available = package.identity;
    if (identity.id != available.id ||
        identity.providerId != available.providerId ||
        identity.version != available.version) {
      throw const RemoteException(
        'driverUnavailable',
        'Local driver package is unavailable.',
      );
    }
    return package;
  }
}
