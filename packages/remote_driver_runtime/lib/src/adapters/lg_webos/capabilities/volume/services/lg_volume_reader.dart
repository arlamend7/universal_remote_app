import 'package:remote_core/remote_core.dart';

import '../../../commands/services/lg_command_channel.dart';

/// Volume and mute are independent feedback queries on LG firmware.
final class LgVolumeReader {
  LgVolumeReader(this.channel);
  final LgCommandChannel channel;

  Future<VolumeState> read() async =>
      decode(await channel.query('audio/getVolume'));

  Future<VolumeState> decode(Map<String, Object?> response) async {
    final nested = response['volumeStatus'];
    final status = nested is Map<String, Object?> ? nested : response;
    final volume = status['volume'] ?? response['volume'];
    if (volume is! int || volume < 0 || volume > 100) {
      throw const RemoteException(
        'protocol',
        'The TV did not report a valid volume level.',
      );
    }
    final muted = _mute(status) ?? _mute(response) ?? await _readMute();
    return VolumeState(volume, muted);
  }

  bool? _mute(Map<String, Object?> response) {
    final value = response['mute'] ?? response['muted'];
    return value is bool ? value : null;
  }

  Future<bool?> _readMute() async {
    try {
      return _mute(await channel.query('audio/getMute'));
    } on RemoteException {
      // Mute feedback is optional; never invent it or revoke volume commands.
      return null;
    }
  }
}
