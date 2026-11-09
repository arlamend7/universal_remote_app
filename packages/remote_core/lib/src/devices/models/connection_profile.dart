import '../../device.dart';

/// Provider configuration and evidence of protocol compatibility.
/// Authorization remains in the provider's credential store.
final class ConnectionProfile {
  ConnectionProfile(
    this.device, {
    required this.confirmed,
    this.userAssociated = false,
  }) {
    if (confirmed &&
        (device.providerId.trim().isEmpty || device.endpoints.isEmpty)) {
      throw ArgumentError(
        'A connection profile needs a provider and endpoint.',
      );
    }
  }

  final RemoteDevice device;
  final bool confirmed;
  final bool userAssociated;
  String get id => device.id;
  String get providerId => device.providerId;
}
