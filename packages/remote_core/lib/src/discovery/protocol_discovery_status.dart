import 'discovery_protocol.dart';
import '../discovery.dart';
import 'discovery_status.dart';

final class ProtocolDiscoveryStatus {
  const ProtocolDiscoveryStatus({
    required this.protocolId,
    required this.status,
    this.providerLabel,
    this.providerId,
    this.serviceType,
    this.duration = Duration.zero,
    this.deviceCount = 0,
    this.failure,
    this.observations = const {},
  });

  final DiscoveryProtocol protocolId;

  /// The searching provider family's label; null for protocol-wide scans.
  final String? providerLabel;
  final String? providerId;
  final String? serviceType;
  final DiscoveryStatus status;
  final Duration duration;
  final int deviceCount;
  final DiscoveryFailure? failure;
  final Map<String, int> observations;
}
