/// A mapping validated by its engine: the only form in which integration
/// JSON can reach a device. Constructed exclusively by
/// [ProtocolEngine.compile].
abstract interface class EngineOperation {
  /// The engine call, such as `ssap.request` or `remote-v2.key`.
  String get kind;

  /// The validated parameters, for diagnostics of the selected mapping.
  Map<String, Object?> describe();
}
