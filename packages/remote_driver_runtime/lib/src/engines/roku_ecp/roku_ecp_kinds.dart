/// Operation kinds executed by the Roku External Control Protocol engine.
abstract final class RokuEcpKinds {
  static const key = 'roku-ecp.key';
  static const text = 'roku-ecp.text';
  static const launch = 'roku-ecp.launch';
  static const applications = 'roku-ecp.applications';
  static const inputs = 'roku-ecp.inputs';
  static const selectInput = 'roku-ecp.select-input';
  static const channels = 'roku-ecp.channels';
  static const readContent = 'roku-ecp.read-content';
  static const playback = 'roku-ecp.playback';

  static const all = {
    key,
    text,
    launch,
    applications,
    inputs,
    selectInput,
    channels,
    readContent,
    playback,
  };

  /// Documented ECP keypress names (plus `PowerOn`, accepted by some TVs in
  /// network standby). Integrations may only send these.
  static const keys = {
    'Home',
    'Rev',
    'Fwd',
    'Play',
    'Select',
    'Left',
    'Right',
    'Down',
    'Up',
    'Back',
    'InstantReplay',
    'Info',
    'Backspace',
    'Search',
    'Enter',
    'FindRemote',
    'VolumeDown',
    'VolumeMute',
    'VolumeUp',
    'PowerOff',
    'PowerOn',
    'ChannelUp',
    'ChannelDown',
    'InputTuner',
    'InputHDMI1',
    'InputHDMI2',
    'InputHDMI3',
    'InputHDMI4',
    'InputAV1',
  };
}
