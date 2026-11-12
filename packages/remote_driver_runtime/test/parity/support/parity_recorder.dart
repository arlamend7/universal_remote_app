/// Collects every wire message a controller emits, in send order.
final class ParityRecorder {
  final _frames = <Object?>[];

  void add(Object? frame) => _frames.add(frame);

  /// Returns and clears the frames recorded since the previous drain.
  List<Object?> drain() {
    final frames = List<Object?>.of(_frames);
    _frames.clear();
    return frames;
  }
}
