import 'package:remote_core/remote_core.dart';

import 'engine_operation.dart';

/// One authenticated, persistent device session owned by a protocol engine.
abstract interface class EngineSession {
  /// Facts reported or negotiated by the device (feature flags, device-info
  /// fields, reported application IDs) used by capability conditions.
  Map<String, String> get facts;

  /// Emits when [facts] change while connected.
  Stream<void> get factChanges;

  /// Software identified by this session, or null while unknown.
  DeviceSoftwareInformation? get software;

  /// A peer identity proven by the transport (certificate fingerprint).
  String? get verifiedPeerIdentity;

  /// A device identity reported by the protocol, for discovery matching.
  String? get reportedDiscoveryIdentity;

  /// Engine operation kinds that became unusable (for example a secondary
  /// channel closed); the controller withdraws dependent capabilities.
  Stream<Set<String>> get unavailable;

  /// Completes once when the session ends without [close] being called.
  Future<void> get lost;

  /// Runs one validated operation with named [arguments] and returns a
  /// typed result (core models, a list of them, a bool, a string or null).
  Future<Object?> execute(
    EngineOperation operation,
    Map<String, Object?> arguments,
  );

  /// Streams typed state updates for a subscription operation.
  Stream<Object?> subscribe(EngineOperation operation);

  Future<void> close();
}
