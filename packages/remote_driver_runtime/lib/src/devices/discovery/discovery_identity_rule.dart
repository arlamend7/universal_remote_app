import 'package:remote_core/remote_core.dart';

/// How a stable device ID is derived from discovery evidence.
final class DiscoveryIdentityRule {
  DiscoveryIdentityRule({
    required this.source,
    required this.pattern,
    required this.template,
    this.lowercase = false,
    this.peerPort = 6467,
    this.profileFallback = false,
  }) {
    if (!{'usn', 'peer-identity'}.contains(source) ||
        template.length > 128 ||
        !template.contains('{')) {
      throw const FormatException('Invalid discovery identity rule.');
    }
  }

  factory DiscoveryIdentityRule.fromJson(Object? value) {
    final json = IntegrationJson.object(value, 'identity');
    IntegrationJson.keys(
      json,
      const {
        'source',
        'pattern',
        'caseInsensitive',
        'lowercase',
        'template',
        'peerPort',
        'profileFallback',
      },
      required: const {'source', 'template'},
    );
    final pattern = json['pattern'] ?? r'^.+$';
    final template = json['template'];
    if (pattern is! String || pattern.length > 128 || template is! String) {
      throw const FormatException('Invalid discovery identity rule.');
    }
    return DiscoveryIdentityRule(
      source: IntegrationJson.label(json, 'source'),
      pattern: RegExp(pattern, caseSensitive: json['caseInsensitive'] != true),
      template: template,
      lowercase: json['lowercase'] == true,
      peerPort: IntegrationJson.integer(
        {'port': json['peerPort'] ?? 6467},
        'port',
        minimum: 1,
        maximum: 65535,
      ),
      profileFallback: json['profileFallback'] == true,
    );
  }

  /// `usn` (first USN segment) or `peer-identity` (TLS certificate pin).
  final String source;
  final RegExp pattern;

  /// Placeholders: `{providerId}`, `{value}`, `{1}` (first capture group).
  final String template;
  final bool lowercase;
  final int peerPort;

  /// Use a random profile ID when the identity is unavailable.
  final bool profileFallback;
}
