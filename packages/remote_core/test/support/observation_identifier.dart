import 'package:remote_core/remote_core.dart';

class ObservationIdentifier implements ProviderIdentifier {
  ObservationIdentifier(this.id, this.protocol, this.service);
  @override
  final String id;
  final DiscoveryProtocol protocol;
  @override
  String get label => 'Custom provider';
  final String service;

  @override
  DiscoveryRequirements get requirements => DiscoveryRequirements({
    protocol: {service},
  });

  @override
  Future<ProviderMatch?> identify(
    DiscoveryObservation observation,
    DiscoveryCancellation cancellation,
  ) async {
    final endpoint = observation.endpoint;
    if (observation.protocolId != protocol || endpoint == null) {
      return null;
    }
    return ProviderMatch(
      ConnectionProfile(
        RemoteDevice(
          id: id,
          name: observation.metadata['name'] ?? 'TV',
          providerId: id,
          endpoints: [endpoint],
        ),
        confirmed: true,
      ),
      observation,
    );
  }
}
