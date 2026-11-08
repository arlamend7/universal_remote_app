import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_lg_webos/src/commands/services/lg_command_channel.dart';

import 'services/lg_volume_reader.dart';

final class LgVolumeController {
  LgVolumeController(this.channel);
  final LgCommandChannel channel;
  late final _reader = LgVolumeReader(channel);
  Future<void> _send(
    String path, [
    Map<String, Object?> payload = const {},
  ]) async {
    await channel.send(RemoteCapability.volume, path, payload: payload);
  }

  Future<void> volumeUp() => _send('audio/volumeUp');
  Future<void> volumeDown() => _send('audio/volumeDown');
  Future<void> setVolume(int volume) {
    if (volume < 0 || volume > 100) {
      throw ArgumentError('Volume must be between 0 and 100.');
    }
    return _send('audio/setVolume', {'volume': volume});
  }

  Future<void> setMuted(bool muted) => _send('audio/setMute', {'mute': muted});
  Future<VolumeState> readVolume() async => _reader.read();
  Stream<VolumeState> watchVolume() {
    return channel.subscribe('audio/getVolume').asyncMap(_reader.decode);
  }
}
