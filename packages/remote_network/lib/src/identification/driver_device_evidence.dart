import 'package:remote_core/remote_core.dart';

/// Inputs to compatibility resolution from an already identified device.
final class DriverDeviceEvidence {
  DriverDeviceEvidence.fromDevice(
    RemoteDevice device, {
    String? osVersion,
    String? firmwareVersion,
  }) : providerId = device.providerId,
       manufacturer =
           _known(device.softwareInformation?.manufacturer) ??
           _known(device.manufacturer),
       model =
           _known(device.softwareInformation?.model) ?? _known(device.model),
       osVersion = _known(
         device.softwareInformation?.operatingSystemVersion ?? osVersion,
       ),
       firmwareVersion = _known(
         device.softwareInformation?.firmwareVersion ?? firmwareVersion,
       ),
       hardwareModel = _known(device.softwareInformation?.hardwareModel),
       softwareVersion =
           device.softwareInformation?.source ==
               DeviceInformationSource.legacyCache
           ? null
           : _known(device.softwareInformation?.softwareVersion),
       buildNumber = _known(device.softwareInformation?.buildNumber),
       protocolVersion = _known(device.softwareInformation?.protocolVersion),
       endpoints = List.unmodifiable(device.endpoints);

  final String providerId;
  final String? manufacturer, model, osVersion, firmwareVersion;
  final String? hardwareModel, softwareVersion, buildNumber, protocolVersion;
  final List<Uri> endpoints;

  static String? _known(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
