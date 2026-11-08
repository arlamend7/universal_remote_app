import 'dart:async';

import 'package:remote_core/remote_core.dart';

class FakeVolume {
  int level = 20;
  Future<void> volumeUp() async {
    level++;
  }

  Future<void> volumeDown() async {
    level--;
  }

  Future<void> setVolume(int value) async {
    level = value;
  }

  Future<void> setMuted(bool muted) async {}
  Future<VolumeState> readVolume() async => VolumeState(level, false);
  Stream<VolumeState> watchVolume() => const Stream.empty();
}
