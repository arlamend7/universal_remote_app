import 'package:remote_core/remote_core.dart';

/// Read-only network probes discovery may use; none pairs or sends commands.
abstract interface class DiscoveryNetwork {
  /// Whether [address] answers an SSDP search for [service].
  Future<bool> ssdp(
    String address,
    String service,
    DiscoveryCancellation cancellation,
  );

  /// The certificate fingerprint presented on [port], without trusting it.
  Future<String?> peerIdentity(
    String address,
    int port, {
    Duration? timeout,
    bool reportNetworkFailure = false,
  });

  /// The DER (base64) certificate presented by [endpoint].
  Future<String?> certificate(Uri endpoint, {Duration? timeout});

  /// The serial number reported by ECP `query/device-info`.
  Future<String?> ecpSerial(Uri endpoint, DiscoveryCancellation cancellation);
}
