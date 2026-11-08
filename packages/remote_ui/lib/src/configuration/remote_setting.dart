import 'remote_setting_type.dart';

/// One option a definition lets the user change. The editor builds its form
/// from these; elements and primitives read the saved value with the same key.
final class RemoteSetting {
  const RemoteSetting.toggle(this.key, this.label, {bool enabled = false})
    : type = RemoteSettingType.toggle,
      fallback = enabled ? 'true' : 'false',
      minimum = 0,
      maximum = 1,
      divisions = null;

  const RemoteSetting.number(
    this.key,
    this.label, {
    required int this.minimum,
    required int this.maximum,
    required int initial,
  }) : type = RemoteSettingType.number,
       fallback = '$initial',
       divisions = null;

  const RemoteSetting.slider(
    this.key,
    this.label, {
    required double this.minimum,
    required double this.maximum,
    required double initial,
    required int this.divisions,
  }) : type = RemoteSettingType.slider,
       fallback = '$initial';

  final String key;
  final String label;
  final RemoteSettingType type;

  /// Saved value used when the item has none.
  final String fallback;
  final num minimum, maximum;
  final int? divisions;

  String read(Map<String, String> settings) => settings[key] ?? fallback;

  bool isOn(Map<String, String> settings) => read(settings) == 'true';

  double number(Map<String, String> settings) {
    final parsed = double.tryParse(read(settings));
    final value = parsed == null || !parsed.isFinite
        ? double.parse(fallback)
        : parsed;
    return value.clamp(minimum, maximum).toDouble();
  }

  /// A message when [value] cannot be saved, otherwise null.
  String? problem(String value) {
    if (type != RemoteSettingType.number) {
      return null;
    }
    final parsed = int.tryParse(value);
    return parsed == null || parsed < minimum || parsed > maximum
        ? 'Check "$label" ($minimum–$maximum).'
        : null;
  }
}
