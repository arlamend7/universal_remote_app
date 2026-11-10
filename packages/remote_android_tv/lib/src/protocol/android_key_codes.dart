import 'package:remote_core/remote_core.dart';

import 'android_remote_session.dart';

/// Android `KeyEvent` codes for the remote keys this provider can send, or
/// null for a key the TV has no code for.
int? androidKeyCode(RemoteKey key) {
  final digit = int.tryParse(key.wireName);
  if (digit != null) {
    return 7 + digit;
  }
  return switch (key) {
    RemoteKey.enter => 23,
    RemoteKey.settings => AndroidRemoteSession.settingsKey,
    RemoteKey.source => 178,
    RemoteKey.mute => 164,
    RemoteKey.menu => 82,
    RemoteKey.info => 165,
    RemoteKey.guide => 172,
    RemoteKey.exit => 4,
    RemoteKey.red => 183,
    RemoteKey.green => 184,
    RemoteKey.yellow => 185,
    RemoteKey.blue => 186,
    RemoteKey.liveTv => 170,
    RemoteKey.captions => 175,
    _ => null,
  };
}

/// Android `KeyEvent` codes for the media transport actions.
int androidMediaCode(MediaAction action) => switch (action) {
  MediaAction.play => 126,
  MediaAction.pause => 127,
  MediaAction.stop => 86,
  MediaAction.rewind => 89,
  MediaAction.fastForward => 90,
  MediaAction.previous => 88,
  MediaAction.next => 87,
};
