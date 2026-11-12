import '../discovery.dart';
import 'discovery_observation.dart';
import 'discovery_requirements.dart';
import 'provider_match.dart';

abstract interface class ProviderIdentifier {
  /// Human-readable provider family shown while discovering.
  String get label;
  String get id;
  DiscoveryRequirements get requirements;
  Future<ProviderMatch?> identify(
    DiscoveryObservation observation,
    DiscoveryCancellation cancellation,
  );
}
