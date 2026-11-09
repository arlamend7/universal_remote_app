import '../../device.dart';
import '../models/connection_profile.dart';
import '../models/registered_device.dart';

final class DeviceRegistry {
  const DeviceRegistry();

  List<RegisteredDevice> validate(Iterable<RegisteredDevice> devices) {
    final result = List<RegisteredDevice>.unmodifiable(devices);
    final owners = <String, String>{};
    final profiles = <String>{};
    for (final device in result) {
      if (owners.containsKey(device.id)) {
        throw ArgumentError('Saved device and profile IDs must be unique.');
      }
      owners[device.id] = device.id;
      for (final profile in device.profiles) {
        _claimProfile(owners, profiles, device.id, profile.id);
      }
    }
    return result;
  }

  void _claimProfile(
    Map<String, String> owners,
    Set<String> profiles,
    String deviceId,
    String profileId,
  ) {
    final owner = owners[profileId];
    if (!profiles.add(profileId) || (owner != null && owner != deviceId)) {
      throw ArgumentError('Saved device and profile IDs must be unique.');
    }
    owners[profileId] = deviceId;
  }

  RegisteredDevice? find(Iterable<RegisteredDevice> devices, String? id) =>
      devices
          .where(
            (device) =>
                device.id == id ||
                device.profiles.any((profile) => profile.id == id),
          )
          .firstOrNull;

  RegisteredDevice fromProfile(RemoteDevice device) => RegisteredDevice(
    id: device.id,
    name: device.name,
    category: device.category,
    profiles: [ConnectionProfile(device, confirmed: _usable(device))],
    preferredProviderId: device.providerId,
  );

  RegisteredDevice update(
    RegisteredDevice current,
    RemoteDevice configuration,
  ) => RegisteredDevice(
    id: current.id,
    name: current.profiles.length == 1 ? configuration.name : current.name,
    category: current.profiles.length == 1
        ? configuration.category
        : current.category,
    preferredProviderId: current.preferredProviderId,
    profiles: current.profiles.map(
      (profile) => profile.id == configuration.id
          ? ConnectionProfile(
              configuration,
              confirmed:
                  _usable(configuration) &&
                  (profile.confirmed || !_usable(profile.device)),
              userAssociated: profile.userAssociated,
            )
          : profile,
    ),
  );
  bool _usable(RemoteDevice device) =>
      device.providerId.trim().isNotEmpty && device.endpoints.isNotEmpty;
}
