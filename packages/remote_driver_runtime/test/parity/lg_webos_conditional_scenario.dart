/// The LG conditional scenario shared by the legacy and generic tests:
/// volume feedback and Bluetooth rejected, no inputs, the settings app
/// present, live TV in the foreground and webOS 7 software.
const lgConditionalOverrides = <String, Map<String, Object?>?>{
  'ssap://audio/getVolume': null,
  'ssap://com.webos.applicationManager/listApps': {
    'apps': [
      {'id': 'com.palm.app.settings', 'title': 'Settings'},
      {'id': 'com.webos.app.livetv', 'title': 'Live TV'},
    ],
  },
  'ssap://com.webos.applicationManager/getForegroundAppInfo': {
    'appId': 'com.webos.app.livetv',
  },
  'ssap://tv/getCurrentChannel': {
    'channelName': 'Local',
    'channelNumber': '7-1',
  },
  'ssap://tv/getExternalInputList': {'devices': <Object?>[]},
  'ssap://com.webos.service.btaudiosrc/getPairedDevices': null,
  'ssap://com.webos.service.update/getCurrentSWInformation': {
    'product_name': 'webOSTV 7.0',
    'model_name': 'OLED55C2',
    'sw_type': 'FIRMWARE',
    'major_ver': '03',
    'minor_ver': '20.11',
  },
};

const lgConditionalSteps = <String>{
  'connect',
  'evidence',
  'software',
  'readVolume',
  'toggleMute',
  'inputs',
  'openAccessorySettings',
  'currentContent',
  'currentInput',
  'bluetoothAccessories',
  'disconnect',
};
