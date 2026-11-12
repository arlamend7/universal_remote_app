import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

class DeviceSoftwareDetails extends StatelessWidget {
  const DeviceSoftwareDetails({super.key, required this.device, this.live});

  final RemoteDevice device;
  final DeviceSoftwareInformation? live;

  @override
  Widget build(BuildContext context) {
    final information = live ?? device.softwareInformation;
    final reportedAt = information?.identifiedAt?.toLocal();
    final driver = device.metadata;
    final rows = [
      ('Manufacturer', information?.manufacturer ?? device.manufacturer),
      ('Model', information?.model ?? device.model),
      ('Operating system', information?.operatingSystem),
      ('OS version', information?.operatingSystemVersion),
      ('Firmware version', information?.firmwareVersion),
      ('Manufacturer software', information?.softwareVersion),
      ('Build number', information?.buildNumber),
      ('Protocol version', information?.protocolVersion),
      ('Driver integration', driver[DeviceMetadataKeys.integrationId]),
      ('Compatibility profile', driver[DeviceMetadataKeys.profileId]),
      ('Driver package', _shortHash(driver[DeviceMetadataKeys.packageSha256])),
      (
        'Last identified',
        reportedAt == null
            ? null
            : MaterialLocalizations.of(context).formatMediumDate(reportedAt),
      ),
      ('Information source', _source(information?.source)),
    ];
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Device software'),
      subtitle: Text(
        live != null
            ? 'Reported during this connection'
            : information != null
            ? 'Saved information'
            : 'Unknown',
      ),
      children: [
        for (final (label, value) in rows)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            subtitle: Text(value ?? 'Unknown'),
          ),
      ],
    );
  }

  String? _source(DeviceInformationSource? source) => switch (source) {
    DeviceInformationSource.authenticatedSession => 'Authenticated TV session',
    DeviceInformationSource.protocolResponse => 'TV protocol response',
    DeviceInformationSource.discovery => 'Network discovery',
    DeviceInformationSource.legacyCache => 'Previously saved TV information',
    null => null,
  };

  static String? _shortHash(String? sha256) =>
      sha256 == null || sha256.length < 12 ? sha256 : sha256.substring(0, 12);
}
