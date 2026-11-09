import '../devices/models/connection_profile.dart';
import 'discovery_observation.dart';

final class ProviderMatch {
  const ProviderMatch(this.profile, this.evidence);

  final ConnectionProfile profile;
  final DiscoveryObservation evidence;
  String get providerId => profile.providerId;
  bool get confirmed => profile.confirmed;
}
