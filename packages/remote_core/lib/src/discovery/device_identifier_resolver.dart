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
    if (_sameAdvertisedHardware(first, second)) {
      return true;
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

  /// A sighting whose peer identity could not be read is the same device as
  /// another one only when both advertise the same hardware identifier from
  /// the same endpoint. Neither the address nor the identifier is enough alone.
  bool _sameAdvertisedHardware(RemoteDevice first, RemoteDevice second) {
    final value = first.metadata[DeviceMetadataKeys.correlationIdentity];
    if (value == null || value.isEmpty) {
      return false;
    }
    final other = second.metadata[DeviceMetadataKeys.correlationIdentity];
    return other?.toLowerCase() == value.toLowerCase() &&
        first.endpoints.any(second.endpoints.contains);
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
    if (_replaces(matches[index], candidate)) {
      matches[index] = candidate;
    }
  }

  /// A fresh broadcast sighting refreshes a match, but a provisional identity
  /// never replaces a stable one.
  static bool _replaces(ProviderMatch existing, ProviderMatch candidate) =>
      candidate.evidence.protocolId != DiscoveryProtocol.unicast &&
      (candidate.profile.device.stableIdentity ||
          !existing.profile.device.stableIdentity);
}
