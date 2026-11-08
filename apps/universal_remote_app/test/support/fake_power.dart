import 'package:remote_core/remote_core.dart';

final class FakePower {
  int shutdowns = 0;
  bool get canWake => false;
  Future<void> powerOff() async {
    shutdowns++;
  }

  Future<void> wake() async {
    throw const RemoteException('wake', 'Wake is not configured.');
  }
}
