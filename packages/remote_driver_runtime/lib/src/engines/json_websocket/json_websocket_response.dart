import 'package:remote_core/remote_core.dart';

/// Decodes the bounded TV response format used by managed command workflows.
abstract final class JsonWebSocketResponse {
  static VolumeState volume(Map<String, Object?> response) {
    final level = response['volume'];
    final mute = response['muted'];
    if (level is! int ||
        level < 0 ||
        level > 100 ||
        (mute != null && mute is! bool)) {
      throw _invalid;
    }
    return VolumeState(level, mute as bool?);
  }

  static List<DeviceChannel> channels(Map<String, Object?> response) =>
      _entries(
        response['channels'],
        (item) => DeviceChannel(
          _requiredText(item['id']),
          _requiredText(item['name']),
          _requiredText(item['number']),
        ),
      );

  static List<DeviceInput> inputs(Map<String, Object?> response) =>
      _entries(response['inputs'], input);

  static DeviceInput input(Map<String, Object?> response) => DeviceInput(
    _requiredText(response['id']),
    _requiredText(response['name']),
  );

  static List<DeviceApplication> applications(Map<String, Object?> response) =>
      _entries(
        response['applications'],
        (item) => DeviceApplication(
          _requiredText(item['id']),
          _requiredText(item['name']),
        ),
      );

  static List<BluetoothAccessory> accessories(Map<String, Object?> response) =>
      _entries(
        response['accessories'],
        (item) => BluetoothAccessory(
          _requiredText(item['id']),
          _requiredText(item['name']),
          connected: _optionalFlag(item['connected']) ?? false,
        ),
      );

  static CurrentContent content(Map<String, Object?> response) =>
      CurrentContent(
        appId: _optionalText(response['appId']) ?? '',
        appName: _optionalText(response['appName']),
        channelName: _optionalText(response['channelName']),
        channelNumber: _optionalText(response['channelNumber']),
        liveTv: _optionalFlag(response['liveTv']) ?? false,
        programTitle: _optionalText(response['programTitle']),
        position: _duration(response['positionMs']),
        duration: _duration(response['durationMs']),
      );

  static String? application(Map<String, Object?> response) =>
      _optionalText(response['appId']);

  static bool? playback(Map<String, Object?> response) =>
      _optionalFlag(response['playing']);

  static List<T> _entries<T>(
    Object? value,
    T Function(Map<String, Object?>) decode,
  ) {
    if (value is! List || value.length > 512) {
      throw _invalid;
    }
    return List.unmodifiable(
      value.map((entry) {
        if (entry is! Map<String, Object?>) {
          throw _invalid;
        }
        return decode(entry);
      }),
    );
  }

  static String _requiredText(Object? value) {
    final text = _optionalText(value);
    if (text == null || text.isEmpty) {
      throw _invalid;
    }
    return text;
  }

  static String? _optionalText(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! String || value.length > 2048) {
      throw _invalid;
    }
    return value;
  }

  static bool? _optionalFlag(Object? value) {
    if (value == null || value is bool) {
      return value as bool?;
    }
    throw _invalid;
  }

  static Duration? _duration(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! int || value < 0 || value > 864000000) {
      throw _invalid;
    }
    return Duration(milliseconds: value);
  }

  static const _invalid = RemoteException(
    'driverResponse',
    'Invalid TV command response.',
  );
}
