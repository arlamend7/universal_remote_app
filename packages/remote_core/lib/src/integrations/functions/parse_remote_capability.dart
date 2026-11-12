import '../../device.dart';

/// Parses a capability name used by integration metadata.
RemoteCapability parseRemoteCapability(Object? value) {
  final capability = RemoteCapability.values.where(
    (candidate) => candidate.name == value,
  );
  if (capability.isEmpty) {
    throw const FormatException('Unknown remote capability.');
  }
  return capability.single;
}
