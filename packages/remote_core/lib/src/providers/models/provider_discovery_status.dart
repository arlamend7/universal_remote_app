import '../../discovery.dart';
import 'discovery_status.dart';

final class ProviderDiscoveryStatus {
  const ProviderDiscoveryStatus({
    required this.providerId,
    required this.status,
    this.duration = Duration.zero,
    this.deviceCount = 0,
    this.failure,
    this.observations = const {},
  });

  final String providerId;
  final DiscoveryStatus status;
  final Duration duration;
  final int deviceCount;
  final DiscoveryFailure? failure;
  final Map<String, int> observations;
}
