import '../device.dart';
import '../discovery.dart';

/// Verifies a saved device over its configured unicast endpoint.
abstract interface class UnicastProbe {
  Future<bool> probe(RemoteDevice device, DiscoveryCancellation cancellation);
}
