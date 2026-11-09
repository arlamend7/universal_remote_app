import 'discovery_protocol.dart';
/// Untrusted protocol evidence. No observation is an authenticated device ID.
final class DiscoveryObservation {
  DiscoveryObservation({
    required this.protocolId,
    required this.serviceType,
    this.endpoint,
    Map<String, String> metadata = const {},
  }) : metadata = Map.unmodifiable(metadata) {
    if (serviceType.trim().isEmpty) {
      throw ArgumentError('Discovery protocol and service are required.');
    }
    if (metadata.length > 32 || metadata.entries.any(_oversized)) {
      throw ArgumentError('Discovery metadata exceeds its size limit.');
    }
  }

  final DiscoveryProtocol protocolId;
  final String serviceType;
  final Uri? endpoint;
  final Map<String, String> metadata;

  static bool _oversized(MapEntry<String, String> entry) =>
      entry.key.length > 64 || entry.value.length > 1024;
}
