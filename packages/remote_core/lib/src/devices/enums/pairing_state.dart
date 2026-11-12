enum PairingState {
  unknown('unknown'),
  unpaired('unpaired'),
  paired('paired');

  const PairingState(this.id);
  final String id;

  static PairingState? tryParse(Object? id) =>
      values.where((value) => value.id == id).firstOrNull;

  static PairingState parse(Object? id) =>
      tryParse(id) ?? (throw const FormatException('Unknown PairingState.'));
}
