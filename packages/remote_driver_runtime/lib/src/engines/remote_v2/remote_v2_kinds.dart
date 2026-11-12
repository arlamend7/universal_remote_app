/// Operation kinds executed by the Android TV Remote v2 engine.
abstract final class RemoteV2Kinds {
  static const key = 'remote-v2.key';
  static const text = 'remote-v2.text';
  static const submit = 'remote-v2.submit';
  static const appLink = 'remote-v2.app-link';
  static const setVolume = 'remote-v2.set-volume';
  static const setMute = 'remote-v2.set-mute';
  static const readVolume = 'remote-v2.read-volume';
  static const readContent = 'remote-v2.read-content';
  static const volume = 'remote-v2.volume';
  static const content = 'remote-v2.content';

  static const all = {
    key,
    text,
    submit,
    appLink,
    setVolume,
    setMute,
    readVolume,
    readContent,
    volume,
    content,
  };
}
