import 'discovery_protocol.dart';

/// Protocol IDs map to exact service targets. Preserve spelling on the wire.
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
    final unique = {
      for (final service in services) service.toLowerCase(): service,
    };
    return MapEntry(protocol, Set.unmodifiable(unique.values));
  }
}
