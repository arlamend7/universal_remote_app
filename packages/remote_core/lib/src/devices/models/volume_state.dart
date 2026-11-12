final class VolumeState {
  const VolumeState(this.volume, this.muted);
  final int volume;

  /// Null when the device reports volume without exposing mute feedback.
  final bool? muted;
}
