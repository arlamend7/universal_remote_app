import 'package:remote_core/remote_core.dart';

final class AndroidAudioOutput {
  const AndroidAudioOutput(
    this.id,
    this.mode,
    this.min,
    this.max,
    this.level,
    this.muted,
  );

  final int id;
  final int mode;
  final int min;
  final int max;
  final int level;
  final bool muted;

  bool get absolute => mode == 2;
  bool get adjustable => mode == 1 || absolute;

  VolumeState get reading =>
      VolumeState((100 * (level - min) / (max - min)).round(), muted);

  int fromPercent(int percent) => min + ((max - min) * percent / 100).round();

  static AndroidAudioOutput? parse(Map<int, Object> fields) {
    if (fields case {6: final int max}) {
      final id = fields[1] ?? 0;
      final mode = fields[4] ?? 0;
      final min = fields[5] ?? 0;
      final level = fields[7] ?? 0;
      final muted = fields[8] ?? 0;
      if (id is int &&
          id >= 0 &&
          mode is int &&
          min is int &&
          min >= 0 &&
          max > min &&
          level is int &&
          level >= min &&
          level <= max &&
          (muted == 0 || muted == 1)) {
        return AndroidAudioOutput(id, mode, min, max, level, muted == 1);
      }
    }
    return null;
  }
}
