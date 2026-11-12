import 'package:remote_core/remote_core.dart';

/// Software reported by `getCurrentSWInformation`; unknown fields stay null.
///
/// When [osVersionPrefix] is given (for example `webOSTV `), the numeric
/// version after it in `product_name` becomes the operating-system version;
/// manufacturer firmware (`major_ver.minor_ver`) is kept separately.
DeviceSoftwareInformation? ssapSoftwareInformation(
  Map<String, Object?> info, {
  String? osVersionPrefix,
  String? operatingSystem,
}) {
  const fields = [
    'model_name',
    'product_name',
    'version',
    'sw_type',
    'major_ver',
    'minor_ver',
  ];
  final raw = <String, String>{
    for (final field in fields)
      if (info[field] case final String value
          when value.trim().isNotEmpty && value.length <= 256)
        field: value,
  };
  if (raw.isEmpty) {
    return null;
  }
  final major = raw['major_ver'];
  final minor = raw['minor_ver'];
  final isFirmware = raw['sw_type']?.toUpperCase() == 'FIRMWARE';
  return DeviceSoftwareInformation(
    source: DeviceInformationSource.authenticatedSession,
    model: raw['model_name'],
    operatingSystem: operatingSystem,
    operatingSystemVersion: _osVersion(raw['product_name'], osVersionPrefix),
    firmwareVersion: isFirmware && major != null && minor != null
        ? '$major.$minor'
        : null,
    identifiedAt: DateTime.now(),
    raw: raw,
  );
}

String? _osVersion(String? product, String? prefix) {
  if (product == null || prefix == null || !product.startsWith(prefix)) {
    return null;
  }
  final version = product.substring(prefix.length).trim();
  return RegExp(r'^\d{1,3}(?:\.\d{1,4}){0,3}$').hasMatch(version)
      ? version
      : null;
}
