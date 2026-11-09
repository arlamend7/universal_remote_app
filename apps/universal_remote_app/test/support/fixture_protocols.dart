import 'package:remote_core/remote_core.dart';

import 'fake_provider.dart';

DiscoveryRegistry fixtureProtocols(Iterable<FakeProvider> providers) {
  final byService = {
    for (final provider in providers) provider.service: provider,
  };
  return DiscoveryRegistry()
    ..register(DiscoveryProtocol.ssdp, (service, token, observe) async {
      await byService[service]!.search(service, token, observe);
    });
}
