import 'dart:async';

import 'package:remote_core/remote_core.dart';

import 'test_controller.dart';

final class TestProvider implements DeviceProvider {
  TestProvider(
    this.id,
    this.items, {
    this.fail = false,
    this.hang = false,
    this.failConnect = false,
  });
  @override
  final String id;
  final List<RemoteDevice> items;
  final bool fail;
  final bool hang;
  final bool failConnect;
  DiscoveryCancellation? token;
  TestController? last;
  @override
  bool supports(RemoteDevice device) => device.providerId == id;
  @override
  Future<List<RemoteDevice>> discover(
    DiscoveryCancellation cancellation,
  ) async {
    token = cancellation;
    if (fail) throw StateError('Provider failed');
    if (hang) {
      await cancellation.whenCancelled;
      return [];
    }
    return items;
  }

  @override
  RemoteBase createController(RemoteDevice device) =>
      last = TestController(device, fail: failConnect);
}
