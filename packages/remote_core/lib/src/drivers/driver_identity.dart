import 'driver_version.dart';

/// A package version and its stable provider namespace.
final class DriverIdentity {
  DriverIdentity({
    required this.id,
    required this.providerId,
    required this.version,
  }) {
    if (!_validId(id) || !_validId(providerId)) {
      throw const FormatException('Invalid driver or provider ID.');
    }
  }

  final String id, providerId;
  final DriverVersion version;

  static final _format = RegExp(r'^[a-z][a-z0-9._-]{0,79}$');

  static bool _validId(String id) => _format.firstMatch(id)?.end == id.length;
}
