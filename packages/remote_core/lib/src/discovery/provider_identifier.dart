import '../discovery.dart';
import '../providers/models/provider_identity.dart';
import 'discovery_observation.dart';
import 'discovery_requirements.dart';
import 'provider_match.dart';

abstract interface class ProviderIdentifier {
  ProviderIdentity get identity;
  String get id;
  DiscoveryRequirements get requirements;
  Future<ProviderMatch?> identify(
    DiscoveryObservation observation,
    DiscoveryCancellation cancellation,
  );
}
