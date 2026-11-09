import '../device.dart';
import '../devices/models/connection_profile.dart';
import '../discovery.dart';
import 'discovery_observation.dart';
import 'discovery_protocol.dart';
import 'is_local_probe_address.dart';
import 'provider_match.dart';
import 'unicast_probe.dart';

final class SavedAddressDiscovery {
  const SavedAddressDiscovery();

  Future<void> search(
    UnicastProbe probe,
    List<RemoteDevice> candidates,
    DiscoveryCancellation token,
    void Function(ProviderMatch) found,
  ) async {
    Object? failure;
    for (var start = 0; start < candidates.length; start += 8) {
      if (token.isCancelled) {
        return;
      }
      await Future.wait(
        candidates.skip(start).take(8).map((device) async {
          try {
            await _probeDevice(probe, device, token, found);
          } catch (error) {
            failure ??= error;
          }
        }),
      );
    }
    if (failure case final error?) {
      throw error;
    }
  }

  Future<void> _probeDevice(
    UnicastProbe probe,
    RemoteDevice device,
    DiscoveryCancellation token,
    void Function(ProviderMatch) found,
  ) async {
    final endpoint = device.endpoints.singleOrNull;
    if (token.isCancelled ||
        endpoint == null ||
        !isLocalProbeAddress(endpoint.host)) {
      return;
    }
    token.record('unicast.attempted');
    if (!await probe.probe(device, token) || token.isCancelled) {
      return;
    }
    found(
      ProviderMatch(
        ConnectionProfile(device, confirmed: true),
        DiscoveryObservation(
          protocolId: DiscoveryProtocol.unicast,
          serviceType: 'saved-address',
          endpoint: endpoint,
        ),
      ),
    );
  }
}
