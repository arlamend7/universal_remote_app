import 'package:remote_core/remote_core.dart';

import 'driver_package.dart';

/// Distribution sources verify the requested package before returning it.
abstract interface class DriverPackageRepository {
  Future<DriverPackage> fetch(DriverIdentity identity);
}
