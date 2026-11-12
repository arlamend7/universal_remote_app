import '../devices/models/device_metadata_keys.dart';
import '../device.dart';
import '../devices/models/registered_device.dart';
import 'provider_match.dart';
import 'discovery_protocol.dart';

/// Correlates only within explicit provider namespaces. An unverified address,
/// name, MAC or cross-provider identifier is insufficient identity evidence.
final class DeviceIdentifierResolver {
  const DeviceIdentifierResolver();

  bool same(RemoteDevice first, RemoteDevice second) {
    if (first.providerId != second.providerId || first.providerId.isEmpty) {
      return false;
    }
    final firstPeer = _peer(first);
    final secondPeer = _peer(second);
    if (firstPeer != null && secondPeer != null) {
      return firstPeer == secondPeer;
    }
    if (first.id == second.id &&
        first.endpoints.any(second.endpoints.contains) &&
        _hasSavedIdentity(first, second)) {
      return true;
    }
    return first.stableIdentity &&
        second.stableIdentity &&
        first.id == second.id &&
        first.endpoints.any(second.endpoints.contains);
  }

  bool _hasSavedIdentity(RemoteDevice first, RemoteDevice second) {
    for (final key in [
      DeviceMetadataKeys.trustedCertificateDer,
      DeviceMetadataKeys.discoveryIdentity,
    ]) {
      final value = first.metadata[key];
      if (value != null && value.isNotEmpty && value == second.metadata[key]) {
        return true;
      }
    }
    return false;
  }

  String? _peer(RemoteDevice device) =>
      device.metadata[DeviceMetadataKeys.verifiedPeerIdentity] ??
      device.metadata['advertisedPeerIdentity'];

  RegisteredDevice resolve(ProviderMatch match) {
    final profile = match.profile;
    return RegisteredDevice(
      id: profile.id,
      name: profile.device.name,
      category: profile.device.category,
      profiles: [profile],
      preferredProviderId: match.providerId,
    );
  }

  void add(List<ProviderMatch> matches, ProviderMatch candidate) {
    final index = matches.indexWhere(
      (match) => same(match.profile.device, candidate.profile.device),
    );
    if (index == -1) {
      matches.add(candidate);
      return;
    }
    if (candidate.evidence.protocolId != DiscoveryProtocol.unicast) {
      matches[index] = candidate;
    }
  }
}
