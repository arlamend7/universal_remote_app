import 'package:remote_core/remote_core.dart';

import 'observation_identifier.dart';

final class UnicastIdentifier extends ObservationIdentifier
    implements UnicastProbe {
  UnicastIdentifier(this.onProbe)
    : super('working', DiscoveryProtocol.ssdp, 'test');

  final Future<bool> Function(RemoteDevice) onProbe;

  @override
  Future<bool> probe(RemoteDevice device, DiscoveryCancellation cancellation) =>
      onProbe(device);
}
