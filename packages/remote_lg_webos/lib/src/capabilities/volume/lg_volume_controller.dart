import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_lg_webos/src/commands/services/lg_command_channel.dart';

import 'services/lg_volume_reader.dart';

final class LgVolumeController {
  LgVolumeController(this.channel, {this.bindings});
  final DriverBindings? bindings;
  final LgCommandChannel channel;
  late final _reader = LgVolumeReader(channel);
  Future<void> _send(
    RemoteCapability capability,
    String path, [
    Map<String, Object?> payload = const {},
  ]) async {
    await channel.send(capability, path, payload: payload);
  }

  Future<void> volumeUp() =>
      _send(RemoteCapability.volume, _path('volume-up', 'audio/volumeUp'));
  Future<void> volumeDown() =>
      _send(RemoteCapability.volume, _path('volume-down', 'audio/volumeDown'));
  Future<void> setVolume(int volume) {
    if (volume < 0 || volume > 100) {
      throw ArgumentError('Volume must be between 0 and 100.');
    }
    return _send(
      RemoteCapability.absoluteVolume,
      _path('set-volume', 'audio/setVolume'),
      {'volume': volume},
    );
  }

  Future<void> setMuted(bool muted) => _send(
    RemoteCapability.mute,
    _path('set-mute', 'audio/setMute'),
    {'mute': muted},
  );
  String _path(String id, String fallback) =>
      bindings?.select(id, fallback) ?? fallback;

  Future<void> toggleMute() async =>
      setMuted(!((await readVolume()).muted ?? false));
  Future<VolumeState> readVolume() async => _reader.read();
  Stream<VolumeState> watchVolume() {
    return channel
        .subscribe(
          'audio/getVolume',
          capability: RemoteCapability.volumeFeedback,
        )
        .asyncMap(_reader.decode);
  }
}
