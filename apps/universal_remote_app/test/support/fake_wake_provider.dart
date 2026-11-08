import 'package:remote_core/remote_core.dart';

import 'fake_controller.dart';
import 'fake_provider.dart';

class FakeWakeProvider extends FakeProvider
    implements DeviceWakeProvider, DeviceConnectionPolicy {
  FakeWakeProvider({
    this.requiresMac = false,
    this.startupFailures = 0,
    super.wakeAddress,
  }) : super(enabledControls: true);
  final bool requiresMac;
  int startupFailures;

  @override
  RemoteBase createController(RemoteDevice device) {
    if (wakes == 0 || startupFailures == 0) {
      return super.createController(device);
    }
    startupFailures--;
    return last = FakeController(
      device,
      startupFailure: const RemoteException('connectionRefused', 'Starting up'),
    );
  }

  @override
  bool sameConnection(RemoteDevice previous, RemoteDevice next) => true;

  @override
  DeviceCategory get category => DeviceCategory.television;

  @override
  bool canReviewCertificate(RemoteDevice device, String? errorCode) => false;

  @override
  RemoteDevice trustCertificate(RemoteDevice device, String certificate) =>
      device;

  @override
  RemoteDevice mergeDiscovered(RemoteDevice saved, RemoteDevice discovered) =>
      discovered;

  @override
  bool canRetryAfterWake(Object error) =>
      error is RemoteException && error.code == 'connectionRefused';

  RemoteDevice? wakeTarget;
  int wakes = 0;
  @override
  bool canWakeDevice(RemoteDevice device) =>
      supports(device) &&
      (!requiresMac || device.metadata['macAddress'] != null);
  @override
  Future<void> wakeDevice(RemoteDevice device) async {
    wakes++;
    wakeTarget = device;
  }
}
