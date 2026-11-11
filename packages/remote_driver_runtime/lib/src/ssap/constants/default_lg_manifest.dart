/// Minimal unsigned prompt manifest. Firmware-dependent permissions are verified
/// by actual operations; no copied vendor identities or baked-in signatures.
const defaultLgManifest = <String, Object?>{
  'manifestVersion': 1,
  'appVersion': '1.0',
  'permissions': <String>[
    'CONTROL_AUDIO',
    'CONTROL_INPUT_TV',
    'CONTROL_MOUSE_AND_KEYBOARD',
    'CONTROL_POWER',
    'LAUNCH',
    'READ_INSTALLED_APPS',
    'READ_INPUT_DEVICE_LIST',
    'READ_NETWORK_STATE',
    'READ_RUNNING_APPS',
    'READ_CURRENT_CHANNEL',
    'READ_TV_CHANNEL_LIST',
    'CONTROL_INPUT_TEXT',
    'READ_APP_STATUS',
    'CONTROL_INPUT_MEDIA_PLAYBACK',
  ],
};
