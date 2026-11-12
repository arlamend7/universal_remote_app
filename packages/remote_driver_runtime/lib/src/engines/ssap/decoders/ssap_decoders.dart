import 'package:remote_core/remote_core.dart';

import 'ssap_application_list.dart';

/// Volume and mute are independent feedback queries on some firmware; mute
/// is optional and never invented.
Future<VolumeState> decodeSsapVolume(
  Map<String, Object?> response,
  Future<Map<String, Object?>> Function()? readMute,
) async {
  final nested = response['volumeStatus'];
  final status = nested is Map<String, Object?> ? nested : response;
  final volume = status['volume'] ?? response['volume'];
  if (volume is! int || volume < 0 || volume > 100) {
    throw const RemoteException(
      'protocol',
      'The TV did not report a valid volume level.',
    );
  }
  final muted = _mute(status) ?? _mute(response) ?? await _optional(readMute);
  return VolumeState(volume, muted);
}

bool? _mute(Map<String, Object?> response) {
  final value = response['mute'] ?? response['muted'];
  return value is bool ? value : null;
}

Future<bool?> _optional(
  Future<Map<String, Object?>> Function()? readMute,
) async {
  if (readMute == null) {
    return null;
  }
  try {
    return _mute(await readMute());
  } on RemoteException {
    return null;
  }
}

SsapApplicationList decodeSsapApplications(
  Map<String, Object?> response,
  String? host,
) {
  final items = response['apps'];
  if (items is! List) {
    throw const RemoteException(
      'protocol',
      'The TV returned an invalid application list.',
    );
  }
  final rows = items.whereType<Map<String, dynamic>>();
  final apps = <String, DeviceApplication>{};
  for (final item in rows.where(_visible)) {
    final id = item['id'] as String;
    apps.putIfAbsent(
      id,
      () => DeviceApplication(
        id,
        (item['title'] as String).trim(),
        artwork: _artwork(item['icon'], host),
      ),
    );
  }
  return SsapApplicationList(apps.values.toList(), {
    for (final item in rows)
      if (item['id'] case final String id) id,
  });
}

bool _visible(Map<String, dynamic> item) {
  final id = item['id'];
  final title = item['title'];
  return item['visible'] != false &&
      id is String &&
      id.trim().isNotEmpty &&
      title is String &&
      title.trim().isNotEmpty;
}

Uri? _artwork(Object? value, String? host) {
  if (value is! String || value.length > 1024 || host == null) {
    return null;
  }
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.host != host ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      !{'http', 'https'}.contains(uri.scheme)) {
    return null;
  }
  return uri;
}

List<DeviceInput> decodeSsapInputs(Map<String, Object?> response) {
  final items = response['devices'];
  if (items is! List) {
    throw const RemoteException(
      'protocol',
      'The TV returned an invalid input list.',
    );
  }
  return [
    for (final input in items.whereType<Map<String, dynamic>>())
      if (input['id'] case final String id)
        if (input['label'] case final String label) DeviceInput(id, label),
  ];
}

List<DeviceChannel> decodeSsapChannels(Map<String, Object?> response) {
  final channels = response['channelList'];
  if (channels is! List) {
    throw const RemoteException(
      'channels',
      'The TV did not report a channel list.',
    );
  }
  return [
    for (final item in channels.whereType<Map<String, dynamic>>())
      if (item['channelId'] case final String id)
        DeviceChannel(
          id,
          item['channelName'] as String? ?? 'Channel',
          item['channelNumber'] as String? ?? '',
        ),
  ];
}

final _bluetoothAddress = RegExp(
  r'^(?:[0-9a-f]{2}:){5}[0-9a-f]{2}$',
  caseSensitive: false,
);

List<BluetoothAccessory> decodeSsapAccessories(Map<String, Object?> response) {
  final devices = response['devices'];
  if (devices is! List) {
    throw const RemoteException(
      'protocol',
      'The TV did not return a Bluetooth device list.',
    );
  }
  return devices
      .whereType<Map<String, dynamic>>()
      .map(_accessory)
      .whereType<BluetoothAccessory>()
      .toList();
}

BluetoothAccessory? _accessory(Map<String, dynamic> entry) {
  final id = entry['address'];
  final state = entry['state'];
  if (id is! String ||
      !_bluetoothAddress.hasMatch(id) ||
      (state != 'connected' && state != 'disconnected')) {
    return null;
  }
  final name = entry['name'];
  return BluetoothAccessory(
    id.toUpperCase(),
    name is String && name.trim().isNotEmpty
        ? name.trim()
        : 'Bluetooth audio device',
    connected: state == 'connected',
  );
}
