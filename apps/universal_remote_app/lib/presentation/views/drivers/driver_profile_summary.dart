import 'package:remote_core/remote_core.dart';

String driverProfileSummary(DriverCompatibility profile) => [
  '${profile.id} · revision ${profile.version}',
  if (profile.models.isNotEmpty) 'Models ${profile.models.join(', ')}',
  if (profile.hardwareModel case final value?) 'Hardware model $value',
  if (profile.osVersion case final value?) 'OS $value',
  if (profile.firmwareVersion case final value?) 'Firmware $value',
  if (profile.softwareVersion case final value?) 'Software $value',
  if (profile.buildNumber case final value?) 'Build $value',
  if (profile.protocolVersion case final value?) 'Protocol $value',
].join(' · ');
