import 'dart:async';

import 'package:remote_core/remote_core.dart';

final class TestController extends DeviceController {
  TestController(this.device, {this.fail = false});
  @override
  final RemoteDevice device;
  final bool fail;
  bool disposed = false;
  @override
  DeviceConnectionState state = DeviceConnectionState.disconnected;
  @override
  Stream<DeviceConnectionState> get connectionStates => const Stream.empty();
  @override
  List<CapabilityEvidence> get evidence => const [
    CapabilityEvidence(
      RemoteCapability.volume,
      CapabilitySource.driver,
      CapabilityAvailability.known,
    ),
  ];
  @override
  bool get canWake => false;
  @override
  Future<void> powerOff() async {}
  @override
  Future<void> wake() async {}
  @override
  Future<void> connect() async {
    if (fail) throw const RemoteException('test', 'Failed');
    state = DeviceConnectionState.connected;
  }

  @override
  Future<void> disconnect() async {
    state = DeviceConnectionState.disconnected;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await disconnect();
  }
}
