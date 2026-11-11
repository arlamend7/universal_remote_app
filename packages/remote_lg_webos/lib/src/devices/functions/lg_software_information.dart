import 'package:remote_core/remote_core.dart';

DeviceSoftwareInformation? lgSoftwareInformation(Map<String, Object?> info) {
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
    operatingSystem: 'webOS',
    firmwareVersion: isFirmware && major != null && minor != null
        ? '$major.$minor'
        : null,
    identifiedAt: DateTime.now(),
    raw: raw,
  );
}
