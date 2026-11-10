import 'package:remote_android_tv/src/protocol/android_key_codes.dart';
import 'package:remote_core/remote_core.dart';
import 'package:test/test.dart';

void main() {
  test('special keys map to Android key codes', () {
    expect(androidKeyCode(RemoteKey.menu), 82);
    expect(androidKeyCode(RemoteKey.info), 165);
    expect(androidKeyCode(RemoteKey.guide), 172);
    expect(androidKeyCode(RemoteKey.exit), 4);
    expect(
      [
        RemoteKey.red,
        RemoteKey.green,
        RemoteKey.yellow,
        RemoteKey.blue,
      ].map(androidKeyCode),
      [183, 184, 185, 186],
    );
  });

  test(
    'digits, mute and source keep their codes; unknown keys map to null',
    () {
      expect(androidKeyCode(RemoteKey.digit0), 7);
      expect(androidKeyCode(RemoteKey.digit9), 16);
      expect(androidKeyCode(RemoteKey.mute), 164);
      expect(androidKeyCode(RemoteKey.source), 178);
      expect(androidKeyCode(RemoteKey.replay), isNull);
    },
  );

  test('media actions include previous and next track', () {
    expect(androidMediaCode(MediaAction.previous), 88);
    expect(androidMediaCode(MediaAction.next), 87);
    expect(androidMediaCode(MediaAction.play), 126);
  });
}
