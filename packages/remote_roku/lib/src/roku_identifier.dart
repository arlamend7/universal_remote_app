import 'dart:io';

import 'package:remote_core/remote_core.dart';

import 'roku_endpoint.dart';

final class RokuIdentifier implements ProviderIdentifier {
  const RokuIdentifier();

  static final providerId = ProviderIdentity.roku.storageId;

  @override
  ProviderIdentity get identity => ProviderIdentity.roku;
  static const service = 'roku:ecp';

  @override
  String get id => providerId;

  @override
  DiscoveryRequirements get requirements => DiscoveryRequirements({
    DiscoveryProtocol.ssdp: {service},
  });

  @override
  Future<ProviderMatch?> identify(
    DiscoveryObservation observation,
    DiscoveryCancellation cancellation,
  ) async {
    if (cancellation.isCancelled ||
        observation.protocolId != DiscoveryProtocol.ssdp ||
        observation.serviceType.toLowerCase() != service ||
        observation.metadata['st']?.toLowerCase() != service) {
      return null;
    }
    final host = observation.endpoint?.host ?? '';
    final usn = observation.metadata['usn']?.split('::').first ?? '';
    final serial = RegExp(
      r'^uuid:roku:ecp:([a-z0-9-]+)$',
      caseSensitive: false,
    ).firstMatch(usn)?.group(1);
    if (serial == null || !isRokuLanAddress(InternetAddress.tryParse(host))) {
      return null;
    }
    final endpoint = rokuEndpoint(host);
    final location = Uri.tryParse(observation.metadata['location'] ?? '');
    if (location != endpoint && location != endpoint.replace(path: '/')) {
      return null;
    }
    return ProviderMatch(
      ConnectionProfile(
        RemoteDevice(
          id: '$providerId:${serial.toLowerCase()}',
          name: 'Roku ($serial)',
          providerId: id,
          manufacturer: 'Roku',
          category: DeviceCategory.mediaPlayer,
          endpoints: [endpoint],
          metadata: {'usn': usn, 'rokuSerial': serial},
        ),
        confirmed: true,
      ),
      observation,
    );
  }
}
