import 'package:remote_core/remote_core.dart';

/// How a device endpoint is built from a host: `scheme://host:port/path`.
final class EndpointTemplate {
  EndpointTemplate({
    required this.scheme,
    required this.port,
    this.path = '',
    this.keepObservedPort = false,
  }) {
    if (!_schemes.contains(scheme) ||
        port < 1 ||
        port > 65535 ||
        _path.firstMatch(path)?.end != path.length) {
      throw const FormatException('Invalid endpoint template.');
    }
  }

  factory EndpointTemplate.fromJson(Object? value) {
    final json = IntegrationJson.object(value, 'endpoint');
    IntegrationJson.keys(
      json,
      const {'scheme', 'port', 'path', 'keepObservedPort'},
      required: const {'scheme', 'port'},
    );
    final scheme = json['scheme'];
    final path = json['path'] ?? '';
    if (scheme is! String || path is! String) {
      throw const FormatException('Invalid endpoint template.');
    }
    return EndpointTemplate(
      scheme: scheme,
      port: IntegrationJson.integer(json, 'port', minimum: 1, maximum: 65535),
      path: path,
      keepObservedPort: json['keepObservedPort'] == true,
    );
  }

  static const _schemes = {'wss', 'ws', 'tls', 'http', 'https'};
  static final _path = RegExp(r'^(?:/[a-zA-Z0-9._-]{1,64}){0,6}/?$');

  final String scheme;
  final int port;
  final String path;

  /// Use the port the device advertised instead of [port].
  final bool keepObservedPort;

  /// True for unencrypted transports that need explicit user permission.
  bool get insecure => scheme == 'ws' || scheme == 'http';

  Uri build(String host, {int? observedPort}) => Uri(
    scheme: scheme,
    host: host,
    port: keepObservedPort && observedPort != null ? observedPort : port,
    path: path.isEmpty ? null : path,
  );

  bool matches(Uri endpoint) => endpoint == build(endpoint.host);
}
