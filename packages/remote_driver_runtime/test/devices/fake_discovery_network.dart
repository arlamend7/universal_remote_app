import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/devices.dart';

/// Answers discovery probes from fixed values.
final class FakeDiscoveryNetwork implements DiscoveryNetwork {
  FakeDiscoveryNetwork({this.peer, this.serial});

  final String? peer;
  final String? serial;

  @override
  Future<bool> ssdp(String a, String s, DiscoveryCancellation c) async => true;

  @override
  Future<String?> peerIdentity(
    String address,
    int port, {
    Duration? timeout,
    bool reportNetworkFailure = false,
  }) async => peer;

  @override
  Future<String?> certificate(Uri endpoint, {Duration? timeout}) async => null;

  @override
  Future<String?> ecpSerial(Uri e, DiscoveryCancellation c) async => serial;
}
