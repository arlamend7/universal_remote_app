import 'package:remote_core/remote_core.dart';

/// Inputs to compatibility resolution from an already identified device.
final class DriverDeviceEvidence {
  DriverDeviceEvidence.fromDevice(
    RemoteDevice device, {
    String? osVersion,
    String? firmwareVersion,
  }) : providerId = device.providerId,
       manufacturer = _known(device.manufacturer),
       model = _known(device.model),
       osVersion = _known(osVersion),
       firmwareVersion = _known(firmwareVersion),
       endpoints = List.unmodifiable(device.endpoints);

  final String providerId;
  final String? manufacturer, model, osVersion, firmwareVersion;
  final List<Uri> endpoints;

  static String? _known(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
