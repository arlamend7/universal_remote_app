import '../device.dart';

/// Validated mapping data for a compiled protocol adapter.
final class DriverBindings {
  DriverBindings(Map<String, String> commands)
    : commands = Map.unmodifiable(commands);

  final Map<String, String> commands;

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
