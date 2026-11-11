import 'package:remote_core/remote_core.dart';

/// Session-local controllers and the evidence that made them available.
final class LgCapabilityRegistry {
  final _controllers = <RemoteCapability, Object>{};
  final _evidence = <RemoteCapability, CapabilityEvidence>{};
  T? controller<T extends Object>(RemoteCapability kind) {
    final controller = _controllers[kind];
    return controller is T ? controller : null;
  }

  List<CapabilityEvidence> get evidence => List.unmodifiable(_evidence.values);
  void clear() {
    _controllers.clear();
    _evidence.clear();
  }

  void enable(
    RemoteCapability kind,
    Object controller,
    CapabilityAvailability availability, {
    String? reason,
  }) {
    _controllers[kind] = controller;
    record(kind, availability, reason: reason);
  }

  void restrict(Set<RemoteCapability> capabilities) {
    for (final capability in capabilities) {
      _controllers.remove(capability);
      _evidence[capability] = CapabilityEvidence(
        capability,
        CapabilitySource.profile,
        CapabilityAvailability.conditional,
        reason: 'Disabled by the TV software compatibility profile.',
      );
    }
  }

  void disable(RemoteCapability kind, {String? reason}) {
    _controllers.remove(kind);
    record(kind, CapabilityAvailability.unavailable, reason: reason);
  }

  void record(
    RemoteCapability kind,
    CapabilityAvailability availability, {
    String? reason,
  }) {
    _evidence[kind] = CapabilityEvidence(
      kind,
      CapabilitySource.driver,
      availability,
      reason: reason,
    );
  }
}
