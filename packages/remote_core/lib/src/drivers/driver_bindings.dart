import '../device.dart';
import 'driver_compatibility.dart';

/// Validated mapping data for a compiled protocol adapter.
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

  /// The adapter owns each binding's permitted wire values and safe default.
  String select(
    String action,
    String fallback, {
    Set<String> alternatives = const {},
  }) {
    final candidate = commands[action];
    if (candidate != null &&
        (candidate == fallback || alternatives.contains(candidate))) {
      return candidate;
    }
    return fallback;
  }
}

typedef DriverBindingsLookup = DriverBindings? Function(RemoteDevice device);
