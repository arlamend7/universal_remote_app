import 'dart:io';

import 'package:remote_core/remote_core.dart';

import 'roku_endpoint.dart';

import 'package:remote_driver_runtime/roku_ecp.dart';

import 'package:remote_driver_runtime/src/engines/roku_ecp/decoders/ecp_serial.dart';

final class RokuIdentifier
    implements ProviderIdentifier, UnicastProbe, AddressIdentifier {
  const RokuIdentifier();

  static final providerId = ProviderIdentity.roku.storageId;

  ProviderIdentity get identity => ProviderIdentity.roku;

  @override
  String get label => identity.label;
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

  @override
  Future<bool> recognizesAddress(
    String address,
    DiscoveryCancellation cancellation,
  ) async {
    if (cancellation.isCancelled ||
        !isRokuLanAddress(InternetAddress.tryParse(address))) {
      return false;
    }
    final info = await RokuEcpClient(rokuEndpoint(address))
        .query('device-info', cancellation: cancellation);
    return !cancellation.isCancelled && rokuSerial(info) != null;
  }

  @override
  Future<bool> probe(
    RemoteDevice device,
    DiscoveryCancellation cancellation,
  ) async {
    final endpoint = device.endpoints.singleOrNull;
    final expected =
        device.metadata['rokuSerial'] ??
        device.metadata['discoveryIdentity']?.split(':').last;
    if (cancellation.isCancelled ||
        expected == null ||
        endpoint == null ||
        !isRokuLanAddress(InternetAddress.tryParse(endpoint.host)) ||
        endpoint != rokuEndpoint(endpoint.host)) {
      return false;
    }
    final info = await RokuEcpClient(endpoint)
        .query('device-info', cancellation: cancellation);
    final serial = rokuSerial(info);
    return !cancellation.isCancelled &&
        serial?.toLowerCase() == expected.toLowerCase();
  }
}
