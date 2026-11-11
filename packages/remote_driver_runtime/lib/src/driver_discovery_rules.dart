import 'package:remote_core/remote_core.dart';

final class DriverDiscoveryRules {
  DriverDiscoveryRules._(this.requirements, this.port, this.path);

  factory DriverDiscoveryRules.fromJson(Map<String, Object?> json) {
    final port = json['port'];
    final path = json['path'];
    final targets = json['targets'];
    if (json.length != 3 ||
        port is! int ||
        port < 1 ||
        port > 65535 ||
        path is! String ||
        !_validPath(path) ||
        targets is! Map<String, Object?> ||
        targets.isEmpty) {
      throw const FormatException('Invalid driver discovery rules.');
    }
    return DriverDiscoveryRules._(
      DiscoveryRequirements(targets.map(_target)),
      port,
      path,
    );
  }

  final DiscoveryRequirements requirements;
  final int port;
  final String path;

  Uri endpoint(String host) {
    if (!isLocalProbeAddress(host)) {
      throw const FormatException(
        'The driver endpoint must be a local address.',
      );
    }
    return Uri(scheme: 'wss', host: host, port: port, path: path);
  }

  static MapEntry<DiscoveryProtocol, Set<String>> _target(
    String key,
    Object? value,
  ) {
    final protocol = DiscoveryProtocol.values
        .where((id) => id.name == key)
        .firstOrNull;
    if (protocol == null ||
        value is! List<Object?> ||
        value.isEmpty ||
        value.length > 16 ||
        !value.every(_validTarget)) {
      throw const FormatException('Invalid discovery service targets.');
    }
    return MapEntry(protocol, value.cast<String>().toSet());
  }

  static bool _validTarget(Object? value) =>
      value is String && _service.firstMatch(value)?.end == value.length;

  static bool _validPath(String path) =>
      _path.firstMatch(path)?.end == path.length &&
      !path.split('/').any((part) => part == '.' || part == '..');

  static final _path = RegExp(r'^/[a-zA-Z0-9_./-]{0,127}$');
  static final _service = RegExp(r'^[a-zA-Z0-9_:.+/-]{1,128}$');
}
