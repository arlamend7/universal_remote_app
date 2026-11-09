import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../connection/functions/lg_web_os_endpoint.dart';
import 'constants/lg_service_type.dart';

final class LgIdentifier
    implements ProviderIdentifier, UnicastProbe, AddressIdentifier {
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

  @override
  Future<bool> recognizesAddress(
    String address,
    DiscoveryCancellation cancellation,
  ) => probeSsdpAddress(address, lgServiceType, cancellation);

  @override
  Future<bool> probe(
    RemoteDevice device,
    DiscoveryCancellation cancellation,
  ) async {
    final endpoint = device.endpoints.singleOrNull;
    final expected = device.metadata['trustedCertificateDer'];
    if (cancellation.isCancelled ||
        expected == null ||
        endpoint == null ||
        endpoint != lgWebOsEndpoint(endpoint.host)) {
      return false;
    }
    final observed = await inspectPeerCertificate(
      endpoint,
      timeout: const Duration(milliseconds: 450),
    );
    return !cancellation.isCancelled && observed.derBase64 == expected;
  }

  String _name(DiscoveryObservation observation) {
    final name = observation.metadata['friendlyname']?.trim();
    return name == null || name.isEmpty ? 'LG webOS TV' : name;
  }
}
