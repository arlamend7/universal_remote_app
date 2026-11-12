import '../device.dart';
import 'driver_compatibility.dart';

/// Selection metadata for legacy compiled adapters. Wire values are never
/// read from here: integration mappings are executed by protocol engines.
final class DriverBindings {
  DriverBindings(
    Map<String, String> commands, {
    this.profileFor,
    this.selection = const {},
  }) : commands = Map.unmodifiable(commands);

  final Map<String, String> commands;
  final Map<String, String> selection;

  /// Resolves fresh evidence against the release selected for this connection.
  final DriverCompatibility Function(RemoteDevice)? profileFor;

  RemoteDevice describe(RemoteDevice device, DriverCompatibility? profile) =>
      copyDevice(
        device,
        metadata: {
          ...device.metadata,
          ...selection,
          if (profile != null) 'managedDriverProfile': profile.id,
          if (profile != null)
            'managedDriverProfileVersion': '${profile.version}',
        },
      );
}

typedef DriverBindingsLookup = DriverBindings? Function(RemoteDevice device);
