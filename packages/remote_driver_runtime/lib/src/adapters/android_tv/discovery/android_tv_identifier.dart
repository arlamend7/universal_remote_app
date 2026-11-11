import 'package:remote_core/remote_core.dart';

import 'package:remote_driver_runtime/remote_v2.dart';

final class AndroidTvIdentifier
    implements ProviderIdentifier, UnicastProbe, AddressIdentifier {
  const AndroidTvIdentifier({this.inspectIdentity = discoverPeerIdentity});

  static final providerId = ProviderIdentity.androidTv.storageId;

  @override
  ProviderIdentity get identity => ProviderIdentity.androidTv;
  static const service = '_androidtvremote2._tcp';
  final Future<String?> Function(String) inspectIdentity;

  @override
  String get id => providerId;

  @override
  DiscoveryRequirements get requirements => DiscoveryRequirements({
    DiscoveryProtocol.bonjour: {service},
  });

  @override
  Future<ProviderMatch?> identify(
    DiscoveryObservation observation,
    DiscoveryCancellation cancellation,
  ) async {
    final endpoint = observation.endpoint;
    if (cancellation.isCancelled ||
        observation.protocolId != DiscoveryProtocol.bonjour ||
        observation.serviceType != service ||
        endpoint == null ||
        endpoint.host.isEmpty ||
        endpoint.port != 6466) {
      return null;
    }
    final identity = await inspectIdentity(endpoint.host);
    if (cancellation.isCancelled) {
      return null;
    }
    final name = observation.metadata['name']?.trim() ?? '';
    return ProviderMatch(
      ConnectionProfile(
        RemoteDevice(
          id: identity == null ? newProfileId() : 'android-tv-$identity',
          name: name.isEmpty ? 'Android TV' : name,
          providerId: id,
          category: DeviceCategory.television,
          stableIdentity: identity != null,
          metadata: {if (identity != null) 'advertisedPeerIdentity': identity},
          endpoints: [
            Uri(scheme: 'tls', host: endpoint.host, port: endpoint.port),
          ],
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
    if (cancellation.isCancelled) {
      return false;
    }
    final peers = await Future.wait([
      for (final port in [6466, 6467])
        discoverPeerIdentity(address, port: port),
    ]);
    return !cancellation.isCancelled &&
        peers.first != null &&
        peers.first == peers.last;
  }

  @override
  Future<bool> probe(
    RemoteDevice device,
    DiscoveryCancellation cancellation,
  ) async {
    final endpoint = device.endpoints.singleOrNull;
    final expected =
        device.metadata['verifiedPeerIdentity'] ??
        device.metadata['advertisedPeerIdentity'];
    if (cancellation.isCancelled ||
        expected == null ||
        endpoint == null ||
        endpoint != Uri(scheme: 'tls', host: endpoint.host, port: 6466)) {
      return false;
    }
    final observed = await discoverPeerIdentity(
      endpoint.host,
      timeout: const Duration(milliseconds: 450),
      reportNetworkFailure: true,
    );
    return !cancellation.isCancelled && observed == expected;
  }
}
