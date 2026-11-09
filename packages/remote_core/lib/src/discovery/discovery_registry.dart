import 'discovery_protocol.dart';
import '../discovery.dart';
import 'discovery_observation.dart';

typedef DiscoverySearch = Future<void> Function(
  String service,
  DiscoveryCancellation cancellation,
  Future<void> Function(DiscoveryObservation) observe,
);

final class DiscoveryRegistry {
  final _searches = <DiscoveryProtocol, DiscoverySearch>{};

  void register(DiscoveryProtocol protocolId, DiscoverySearch search) {
    if (_searches.containsKey(protocolId)) {
      throw ArgumentError(
        'Discovery protocol IDs must be unique.',
      );
    }
    _searches[protocolId] = search;
  }

  DiscoverySearch? operator [](DiscoveryProtocol protocolId) => _searches[protocolId];
}
