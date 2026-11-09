import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../connection/samsung_endpoint.dart';

final class SamsungIdentifier implements ProviderIdentifier, UnicastProbe {
  const SamsungIdentifier();

  static const service = 'urn:samsung.com:service:MultiScreenService:1';

  @override
  ProviderIdentity get identity => ProviderIdentity.samsungTizen;

  @override
  String get id => identity.storageId;

  @override
  DiscoveryRequirements get requirements => DiscoveryRequirements({
    DiscoveryProtocol.ssdp: {service},
  });

  @override
  Future<ProviderMatch?> identify(
    DiscoveryObservation observation,
    DiscoveryCancellation cancellation,
  ) async {
    final host = observation.endpoint?.host;
    final usn = observation.metadata['usn']?.split('::').first.toLowerCase();
    if (cancellation.isCancelled ||
        observation.protocolId != DiscoveryProtocol.ssdp ||
        observation.serviceType.toLowerCase() != service.toLowerCase() ||
        observation.metadata['st']?.toLowerCase() != service.toLowerCase() ||
        host == null ||
        !isLocalProbeAddress(host) ||
        usn == null ||
        !RegExp(r'^uuid:[0-9a-f-]{16,64}$').hasMatch(usn)) {
      return null;
    }
    final name = observation.metadata['friendlyname']?.trim();
    return ProviderMatch(
      ConnectionProfile(
        RemoteDevice(
          id: '$id:$usn',
          name: name == null || name.isEmpty ? 'Samsung TV' : name,
          providerId: id,
          manufacturer: 'Samsung',
          model: observation.metadata['modelname'],
          category: DeviceCategory.television,
          endpoints: [samsungEndpoint(host)],
        ),
        confirmed: true,
      ),
      observation,
    );
  }

  @override
  Future<bool> probe(
    RemoteDevice device,
    DiscoveryCancellation cancellation,
  ) async {
    final endpoint = device.endpoints.singleOrNull;
    final pin = device.metadata['trustedCertificateDer'];
    if (cancellation.isCancelled ||
        pin == null ||
        endpoint == null ||
        !isLocalProbeAddress(endpoint.host) ||
        endpoint != samsungEndpoint(endpoint.host)) {
      return false;
    }
    final observed = await inspectPeerCertificate(
      endpoint,
      timeout: const Duration(milliseconds: 450),
    );
    return !cancellation.isCancelled && observed.derBase64 == pin;
  }
}
