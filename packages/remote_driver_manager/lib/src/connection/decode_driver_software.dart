import 'package:remote_core/remote_core.dart';

DeviceSoftwareInformation? decodeDriverSoftware(
  Object? response, {
  required bool authenticated,
}) {
  if (response is! Map<String, Object?>) {
    return null;
  }
  const fields = [
    'manufacturer',
    'model',
    'hardwareModel',
    'operatingSystem',
    'operatingSystemVersion',
    'softwareVersion',
    'firmwareVersion',
    'buildNumber',
    'protocolVersion',
  ];
  final values = <String, String>{
    for (final field in fields)
      if (response[field] case final String value
          when value.trim().isNotEmpty && value.length <= 256)
        field: value,
  };
  if (values.isEmpty) {
    return null;
  }
  final source = authenticated
      ? DeviceInformationSource.authenticatedSession
      : DeviceInformationSource.protocolResponse;
  return DeviceSoftwareInformation.fromJson({
    ...values,
    'source': source.name,
    'identifiedAt': DateTime.now().toUtc().toIso8601String(),
    'raw': values,
  });
}
