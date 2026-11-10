import 'dart:convert';
import 'dart:math';

final class RemoteDevice {
  RemoteDevice({
    required this.id,
    required this.name,
    Set<RemoteCapability> capabilities = const {},
    this.providerId = '',
    this.manufacturer,
    this.model,
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
  final DeviceCategory category;
  final List<Uri> endpoints;
  final Map<String, String> metadata;
  final bool stableIdentity;
  final Set<RemoteCapability> capabilities;
  final PairingState pairingState;
}

enum DeviceCategory {
  television,
  airConditioner,
  mediaPlayer,
  speaker,
  light,
  fan,
  projector,
  unknown,
}

enum DeviceConnectionState {
  disconnected,
  connecting,
  pairing,
  connected,
  reconnecting,
}

enum PairingState { unknown, unpaired, paired }

/// Network setup values returned by a provider for display in the app.
final class DeviceNetworkConfiguration {
  const DeviceNetworkConfiguration({
    this.address = '',
    this.certificate = '',
    this.mac = '',
    this.broadcast = '',
    this.legacy = false,
    this.allowInsecurePointer = false,
  });

  final String address, certificate, mac, broadcast;
  final bool legacy, allowInsecurePointer;
}

/// Wake target reported by an authenticated device interface.
final class DeviceWakeAddress {
  const DeviceWakeAddress(this.macAddress, {this.broadcastAddress});
  final String macAddress;
  final String? broadcastAddress;
}

RemoteDevice copyDevice(
  RemoteDevice device, {
  String? name,
  String? model,
  DeviceCategory? category,
  Set<RemoteCapability>? capabilities,
  List<Uri>? endpoints,
  Map<String, String>? metadata,
}) => RemoteDevice(
  id: device.id,
  name: name ?? device.name,
  providerId: device.providerId,
  manufacturer: device.manufacturer,
  model: model ?? device.model,
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

enum CapabilityAvailability {
  advertised,
  known,
  verified,
  unavailable,
  unsupported,
}

enum CapabilitySource {
  advertisement,
  standardDiscovery,
  driver,
  profile,
  learned,
  user,
}

enum RemoteCapability {
  volume,
  volumeFeedback,
  mute,
  navigation,
  power,
  applications,
  inputs,
  media,
  channels,
  currentContent,
  pointer,
  textInput,
  channelSelection,
  climate,
  lighting,
  wake,
  voice,
  gameMode,
  watch,
  currentInput,
  trackNavigation,
  seek,
  playbackMetadata,
  absoluteVolume,
  accessorySettings,
  bluetoothAccessories,
  playbackToggle,
  numericKeys,
  specialKeys,
  tvSettings,
  playbackScan,
  liveTvKey,
  screenPower,
  captionsKey,
  instantReplay,
  channelCatalog,
}
