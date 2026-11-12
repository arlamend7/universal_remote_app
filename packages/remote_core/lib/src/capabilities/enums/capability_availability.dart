enum CapabilityAvailability {
  advertised,
  known,
  verified,
  unavailable,
  unsupported,
  conditional,
  unknown;

  bool get isUsable => this == known || this == verified;
}
