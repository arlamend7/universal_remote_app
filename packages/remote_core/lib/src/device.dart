import 'capabilities/enums/remote_capability.dart';
import 'capabilities/enums/capability_source.dart';
import 'capabilities/enums/capability_availability.dart';
import 'devices/enums/pairing_state.dart';
import 'devices/enums/device_category.dart';

import 'dart:convert';
import 'dart:math';

import 'devices/models/device_software_information.dart';

export 'capabilities/enums/remote_capability.dart';
export 'capabilities/enums/capability_source.dart';
export 'capabilities/enums/capability_availability.dart';
export 'devices/enums/pairing_state.dart';
export 'devices/enums/device_connection_state.dart';
export 'devices/enums/device_category.dart';
export 'devices/models/device_network_configuration.dart';

export 'devices/models/device_wake_address.dart';

final class RemoteDevice {
  RemoteDevice({
    required this.id,
    required this.name,
    Set<RemoteCapability> capabilities = const {},
    this.providerId = '',
    this.manufacturer,
    this.model,
    this.softwareInformation,
    this.category = DeviceCategory.unknown,
    List<Uri> endpoints = const [],
    Map<String, String> metadata = const {},
    this.stableIdentity = true,
    this.pairingState = PairingState.unknown,
  }) : capabilities = Set.unmodifiable(capabilities),
       endpoints = List.unmodifiable(endpoints),
       metadata = Map.unmodifiable(metadata) {
    if (id.trim().isEmpty || name.trim().isEmpty) {
      throw ArgumentError('Device ID and name must not be empty.');
    }
  }
  final String id;
  final String name;
  final String providerId;
  final String? manufacturer;
  final String? model;
  final DeviceSoftwareInformation? softwareInformation;
  final DeviceCategory category;
  final List<Uri> endpoints;
  final Map<String, String> metadata;
  final bool stableIdentity;
  final Set<RemoteCapability> capabilities;
  final PairingState pairingState;
}

RemoteDevice copyDevice(
  RemoteDevice device, {
  String? name,
  String? manufacturer,
  String? model,
  DeviceSoftwareInformation? softwareInformation,
  DeviceCategory? category,
  Set<RemoteCapability>? capabilities,
  List<Uri>? endpoints,
  Map<String, String>? metadata,
}) => RemoteDevice(
  id: device.id,
  name: name ?? device.name,
  providerId: device.providerId,
  manufacturer: manufacturer ?? device.manufacturer,
  model: model ?? device.model,
  softwareInformation: softwareInformation ?? device.softwareInformation,
  category: category ?? device.category,
  stableIdentity: device.stableIdentity,
  endpoints: endpoints ?? device.endpoints,
  metadata: metadata ?? device.metadata,
  pairingState: device.pairingState,
  capabilities: capabilities ?? device.capabilities,
);

/// Random profile identity persists separately from the mutable network address.
String newProfileId() =>
    base64UrlEncode(List<int>.generate(18, (_) => Random.secure().nextInt(256)))
        .replaceAll('=', '');

/// Evidence is distinct from command availability and can change per session.
final class CapabilityEvidence {
  const CapabilityEvidence(
    this.capability,
    this.source,
    this.availability, {
    this.reason,
  });
  final RemoteCapability capability;
  final CapabilitySource source;
  final CapabilityAvailability availability;
  final String? reason;
}
