import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';

final class FixtureDriverRepository implements DriverPackageRepository {
  FixtureDriverRepository(this.packages);

  final List<DriverPackage> packages;
  int requests = 0;

  @override
  Future<DriverPackage> fetch(DriverIdentity identity) async {
    requests++;
    return packages.firstWhere(
      (package) => package.identity.version == identity.version,
      orElse: () =>
          throw const RemoteException('offline', 'The fixture is offline.'),
    );
  }
}
