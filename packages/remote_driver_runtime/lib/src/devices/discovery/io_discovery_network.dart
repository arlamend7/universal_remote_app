import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../../ecp/roku_ecp_client.dart';
import '../../engines/roku_ecp/decoders/ecp_serial.dart';
import '../../remote_v2/security/discover_peer_identity.dart';
import 'discovery_network.dart';

/// Discovery probes over the real network.
final class IoDiscoveryNetwork implements DiscoveryNetwork {
  const IoDiscoveryNetwork();

  @override
  Future<bool> ssdp(
    String address,
    String service,
    DiscoveryCancellation cancellation,
  ) => probeSsdpAddress(address, service, cancellation);

  @override
  Future<String?> peerIdentity(
    String address,
    int port, {
    Duration? timeout,
    bool reportNetworkFailure = false,
  }) => discoverPeerIdentity(
    address,
    port: port,
    timeout: timeout ?? const Duration(milliseconds: 900),
    reportNetworkFailure: reportNetworkFailure,
  );

  @override
  Future<String?> certificate(Uri endpoint, {Duration? timeout}) async =>
      (await inspectPeerCertificate(
        endpoint,
        timeout: timeout ?? const Duration(milliseconds: 450),
      )).derBase64;

  @override
  Future<String?> ecpSerial(
    Uri endpoint,
    DiscoveryCancellation cancellation,
  ) async => rokuSerial(
    await RokuEcpClient(endpoint)
        .query('device-info', cancellation: cancellation),
  );
}
