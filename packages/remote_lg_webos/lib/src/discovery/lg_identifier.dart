import 'package:remote_core/remote_core.dart';

import '../connection/functions/lg_web_os_endpoint.dart';
import 'constants/lg_service_type.dart';

final class LgIdentifier implements ProviderIdentifier {
  const LgIdentifier();

  static final providerId = ProviderIdentity.lgWebOs.storageId;

  @override
  ProviderIdentity get identity => ProviderIdentity.lgWebOs;

  @override
  String get id => providerId;

  @override
  DiscoveryRequirements get requirements => DiscoveryRequirements({
    DiscoveryProtocol.ssdp: {lgServiceType},
  });

  @override
  Future<ProviderMatch?> identify(
    DiscoveryObservation observation,
    DiscoveryCancellation cancellation,
  ) async {
    final host = observation.endpoint?.host;
    final usn = observation.metadata['usn']?.split('::').first;
    if (cancellation.isCancelled ||
        observation.protocolId != DiscoveryProtocol.ssdp ||
        observation.serviceType.toLowerCase() != lgServiceType.toLowerCase() ||
        host == null ||
        host.isEmpty ||
        usn == null ||
        !usn.startsWith('uuid:') ||
        usn.length <= 5) {
      return null;
    }
    return ProviderMatch(
      ConnectionProfile(
        RemoteDevice(
          id: '$id:$usn',
          name: _name(observation),
          providerId: id,
          manufacturer: 'LG',
          model: observation.metadata['modelname'],
          category: DeviceCategory.television,
          endpoints: [lgWebOsEndpoint(host)],
          metadata: observation.metadata,
        ),
        confirmed: true,
      ),
      observation,
    );
  }

  String _name(DiscoveryObservation observation) {
    final name = observation.metadata['friendlyname']?.trim();
    return name == null || name.isEmpty ? 'LG webOS TV' : name;
  }
}
