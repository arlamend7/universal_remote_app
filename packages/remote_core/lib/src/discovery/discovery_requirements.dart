import 'discovery_protocol.dart';
/// Protocol IDs map to exact service targets. Searches may be shared by callers.
final class DiscoveryRequirements {
  DiscoveryRequirements(Map<DiscoveryProtocol, Set<String>> targets)
    : targets = Map.unmodifiable(targets.map(_freeze));

  final Map<DiscoveryProtocol, Set<String>> targets;

  static MapEntry<DiscoveryProtocol, Set<String>> _freeze(
    DiscoveryProtocol protocol,
    Set<String> services,
  ) {
    if (services.any((service) => service.trim().isEmpty)) {
      throw ArgumentError('Discovery targets must be nonempty.');
    }
    return MapEntry(protocol, Set.unmodifiable(services));
  }
}
