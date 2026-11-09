import 'discovery_protocol.dart';
import '../discovery.dart';
import '../providers/models/provider_identity.dart';
import 'discovery_status.dart';

final class ProtocolDiscoveryStatus {
  const ProtocolDiscoveryStatus({
    required this.protocolId,
    required this.status,
    this.provider = ProviderIdentity.custom,
    this.providerId,
    this.serviceType,
    this.duration = Duration.zero,
    this.deviceCount = 0,
    this.failure,
    this.observations = const {},
  });

  final DiscoveryProtocol protocolId;
  final ProviderIdentity provider;
  final String? providerId;
  final String? serviceType;
  final DiscoveryStatus status;
  final Duration duration;
  final int deviceCount;
  final DiscoveryFailure? failure;
  final Map<String, int> observations;
}
