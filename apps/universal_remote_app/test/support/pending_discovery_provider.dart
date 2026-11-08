import 'dart:async';

import 'package:remote_core/remote_core.dart';

import 'fake_provider.dart';

class PendingDiscoveryProvider extends FakeProvider {
  PendingDiscoveryProvider({this.id = 'test'});

  @override
  final String id;

  final response = Completer<List<RemoteDevice>>();
  int calls = 0;
  DiscoveryCancellation? token;
  @override
  Future<List<RemoteDevice>> discover(DiscoveryCancellation cancellation) {
    calls++;
    token = cancellation;
    return response.future;
  }
}
