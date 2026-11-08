import 'dart:async';

import 'fake_controller.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';

import 'test_device.dart';

class FakeProvider implements DeviceProvider {
  FakeProvider({
    this.fail = false,
    this.pairing = false,
    this.enableContentFeedback = true,
    this.enabledControls = false,
    this.wakeAddress,
  });
  final bool fail;
  final bool pairing;
  final bool enabledControls;
  final bool enableContentFeedback;
  final String? wakeAddress;
  FakeController? last;
  @override
  String get id => 'test';
  @override
  bool supports(RemoteDevice device) => device.providerId == id;
  @override
  Future<List<RemoteDevice>> discover(
    DiscoveryCancellation cancellation,
  ) async => [tv];
  @override
  RemoteBase createController(RemoteDevice device) => last = FakeController(
    device,
    failure: fail,
    waitPairing: pairing,
    enabledControls: enabledControls,
    enableContentFeedback: enableContentFeedback,
    wakeAddress: wakeAddress,
  );
}
