import '../../device.dart';
import 'connection_profile.dart';

final class RegisteredDevice {
  RegisteredDevice({
    required this.id,
    required this.name,
    required this.category,
    required Iterable<ConnectionProfile> profiles,
    this.preferredProviderId,
  }) : profiles = List.unmodifiable(profiles) {
    if (id.trim().isEmpty || name.trim().isEmpty || this.profiles.isEmpty) {
      throw ArgumentError('A registered device needs an ID, name and profile.');
    }
    if (this.profiles.map((profile) => profile.id).toSet().length !=
        this.profiles.length) {
      throw ArgumentError('Connection profile IDs must be unique.');
    }
    if (preferredProviderId != null &&
        !this.profiles.any(
          (profile) => profile.providerId == preferredProviderId,
        )) {
      throw ArgumentError(
        'The preferred provider must have a connection profile.',
      );
    }
  }

  final String id;
  final String name;
  final DeviceCategory category;
  final List<ConnectionProfile> profiles;
  final String? preferredProviderId;

  ConnectionProfile get preferredProfile => profiles.firstWhere(
    (profile) => profile.providerId == preferredProviderId,
    orElse: () => profiles.first,
  );
}
