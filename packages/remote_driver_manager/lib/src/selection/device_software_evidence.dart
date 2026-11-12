import 'package:remote_core/remote_core.dart';

/// The software fields compatibility ranges are compared with.
final class DeviceSoftwareEvidence {
  const DeviceSoftwareEvidence({this.os, this.firmware, this.model});

  factory DeviceSoftwareEvidence.of(
    DeviceSoftwareInformation? software, {
    String? model,
  }) => DeviceSoftwareEvidence(
    os: software?.operatingSystemVersion,
    firmware: software?.firmwareVersion,
    model: software?.hardwareModel ?? software?.model ?? model,
  );

  final String? os, firmware, model;

  VersionMatch match(IntegrationCompatibility compatibility) =>
      compatibility.match(os: os, firmware: firmware, model: model);
}
