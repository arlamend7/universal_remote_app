import 'package:remote_core/remote_core.dart';

/// A stable JSON form of controller results; volatile timestamps are omitted.
Object? parityValue(Object? value) => switch (value) {
  null || bool() || num() || String() => value,
  VolumeState() => {'volume': value.volume, 'muted': value.muted},
  DeviceApplication() => {
    'id': value.id,
    'name': value.name,
    // Loopback fixture ports are ephemeral; scheme and path are the contract.
    'artwork': value.artwork == null
        ? null
        : '${value.artwork!.scheme}:${value.artwork!.path}',
  },
  DeviceChannel() => {
    'id': value.id,
    'name': value.name,
    'number': value.number,
  },
  DeviceInput() => {'id': value.id, 'name': value.name},
  BluetoothAccessory() => {
    'id': value.id,
    'name': value.name,
    'connected': value.connected,
  },
  CurrentContent() => _content(value),
  CapabilityEvidence() => '${value.capability.name}:${value.availability.name}',
  Iterable<Object?>() => [for (final item in value) parityValue(item)],
  Map<Object?, Object?>() => {
    for (final entry in value.entries) '${entry.key}': parityValue(entry.value),
  },
  _ => value.toString(),
};

Map<String, Object?> _content(CurrentContent value) => {
  'appId': value.appId,
  'appName': value.appName,
  'channelName': value.channelName,
  'channelNumber': value.channelNumber,
  'liveTv': value.isLiveTv,
  'programTitle': value.programTitle,
  'position': value.position?.inMilliseconds,
  'duration': value.duration?.inMilliseconds,
};

/// Software facts that compatibility resolution depends on.
Map<String, Object?> paritySoftware(DeviceSoftwareInformation? software) => {
  'operatingSystem': software?.operatingSystem,
  'operatingSystemVersion': software?.operatingSystemVersion,
  'softwareVersion': software?.softwareVersion,
  'firmwareVersion': software?.firmwareVersion,
  'buildNumber': software?.buildNumber,
  'manufacturer': software?.manufacturer,
  'model': software?.model,
  'hardwareModel': software?.hardwareModel,
  'protocolVersion': software?.protocolVersion,
  'source': software?.source.name,
  'raw': software?.raw,
};
