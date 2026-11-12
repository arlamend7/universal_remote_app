import 'package:remote_core/remote_core.dart';

import 'discovery_network.dart';
import 'discovery_rules.dart';

/// Identity evidence extracted from one observation.
typedef _Identity = ({String? value, String? group, String? peer});

/// Identifies devices purely from an integration's discovery rules.
final class DeclarativeIdentifier
    implements ProviderIdentifier, UnicastProbe, AddressIdentifier {
  DeclarativeIdentifier(this.providerId, this.rules, this.network);

  final String providerId;
  final DiscoveryRules rules;
  final DiscoveryNetwork network;
  static const _probeTimeout = Duration(milliseconds: 450);

  @override
  String get id => providerId;

  @override
  String get label => rules.label;

  @override
  DiscoveryRequirements get requirements => rules.requirements;

  @override
  Future<ProviderMatch?> identify(
    DiscoveryObservation observation,
    DiscoveryCancellation cancellation,
  ) async {
    final host = observation.endpoint?.host;
    if (cancellation.isCancelled ||
        host == null ||
        host.isEmpty ||
        !_matches(observation, host)) {
      return null;
    }
    final identity = await _identity(observation, host);
    if (cancellation.isCancelled || identity == null) {
      return null;
    }
    return ProviderMatch(
      ConnectionProfile(_device(observation, host, identity), confirmed: true),
      observation,
    );
  }

  @override
  Future<bool> recognizesAddress(
    String address,
    DiscoveryCancellation cancellation,
  ) async {
    final probe = rules.addressProbe;
    if (cancellation.isCancelled || probe == null || !_allowed(address)) {
      return false;
    }
    final recognized = switch (probe['kind']) {
      'ssdp' => await network.ssdp(address, rules.service, cancellation),
      'peer-identity-pair' => await _samePeer(address, probe),
      _ => await _serial(rules.endpoint.build(address), cancellation) != null,
    };
    return !cancellation.isCancelled && recognized;
  }

  @override
  Future<bool> probe(
    RemoteDevice device,
    DiscoveryCancellation cancellation,
  ) async {
    final probe = rules.unicastProbe;
    final endpoint = device.endpoints.singleOrNull;
    final expected = probe == null ? null : _expected(device, probe);
    if (cancellation.isCancelled ||
        expected == null ||
        endpoint == null ||
        !_allowed(endpoint.host) ||
        !rules.endpoint.matches(endpoint)) {
      return false;
    }
    final observed = await _observe(probe!, endpoint, cancellation);
    return !cancellation.isCancelled && _same(probe, observed, expected);
  }

  bool _matches(DiscoveryObservation observation, String host) {
    final service = rules.service.toLowerCase();
    final header = observation.metadata['st']?.toLowerCase();
    return observation.protocolId == rules.protocol &&
        observation.serviceType.toLowerCase() == service &&
        (!rules.requireServiceHeader || header == service) &&
        (rules.port == null || observation.endpoint?.port == rules.port) &&
        _allowed(host) &&
        (!rules.requireLocation || _location(observation, host));
  }

  bool _allowed(String host) => rules.address?.accepts(host) ?? true;

  bool _location(DiscoveryObservation observation, String host) {
    final endpoint = rules.endpoint.build(host);
    final location = Uri.tryParse(observation.metadata['location'] ?? '');
    return location == endpoint || location == endpoint.replace(path: '/');
  }

  Future<_Identity?> _identity(
    DiscoveryObservation observation,
    String host,
  ) async {
    final rule = rules.identity;
    if (rule.source == 'peer-identity') {
      final peer = await network.peerIdentity(host, rule.peerPort);
      if (peer == null && !rule.profileFallback) {
        return null;
      }
      return (value: peer, group: null, peer: peer);
    }
    final raw = observation.metadata['usn']?.split('::').first;
    final value = rule.lowercase ? raw?.toLowerCase() : raw;
    final match = value == null ? null : rule.pattern.firstMatch(value);
    if (match == null || match.end != value!.length) {
      return null;
    }
    return (
      value: value,
      group: match.groupCount > 0 ? match.group(1) : null,
      peer: null,
    );
  }

  RemoteDevice _device(
    DiscoveryObservation observation,
    String host,
    _Identity identity,
  ) {
    final stable = identity.value != null;
    final id = stable
        ? _render(rules.identity.template, identity)
        : newProfileId();
    final model = rules.modelMetadata == null
        ? null
        : observation.metadata[rules.modelMetadata];
    return RemoteDevice(
      id: id,
      name: _name(observation, identity),
      providerId: providerId,
      manufacturer: rules.manufacturer,
      model: model,
      category: rules.category,
      stableIdentity: stable,
      endpoints: [
        rules.endpoint.build(host, observedPort: observation.endpoint?.port),
      ],
      metadata: {
        if (rules.copyMetadata) ...observation.metadata,
        for (final entry in rules.metadata.entries)
          if (_optional(entry.value, identity, observation) case final value?)
            entry.key: value,
      },
    );
  }

  String _name(DiscoveryObservation observation, _Identity identity) {
    final key = rules.name['metadata'] as String?;
    final reported = key == null ? null : observation.metadata[key]?.trim();
    if (reported != null && reported.isNotEmpty) {
      return reported;
    }
    final template = rules.name['template'] as String?;
    if (template != null) {
      return _render(template, identity);
    }
    return (rules.name['fallback'] as String?) ?? rules.label;
  }

  /// Metadata templates may also copy one observed value (`{observed:key}`);
  /// the entry is omitted when the observation did not carry it.
  String? _optional(
    String template,
    _Identity identity,
    DiscoveryObservation observation,
  ) {
    if (template.contains('{peer}') && identity.peer == null) {
      return null;
    }
    final observed = _observedToken.firstMatch(template);
    if (observed == null) {
      return _render(template, identity);
    }
    final value = observation.metadata[observed.group(1)!];
    if (value == null || value.isEmpty) {
      return null;
    }
    return _render(template.replaceAll(observed.group(0)!, value), identity);
  }

  static final _observedToken = RegExp(r'\{observed:([a-z0-9_.-]{1,40})\}');

  String _render(String template, _Identity identity) => template
      .replaceAll('{providerId}', providerId)
      .replaceAll('{value}', identity.value ?? '')
      .replaceAll('{1}', identity.group ?? '')
      .replaceAll('{1:lower}', identity.group?.toLowerCase() ?? '')
      .replaceAll('{peer}', identity.peer ?? '');

  Future<bool> _samePeer(String address, Map<String, Object?> probe) async {
    final ports = (probe['ports'] as List?)?.cast<int>() ?? const [6466, 6467];
    final peers = await Future.wait([
      for (final port in ports) network.peerIdentity(address, port),
    ]);
    return peers.first != null && peers.every((peer) => peer == peers.first);
  }

  Future<String?> _serial(Uri endpoint, DiscoveryCancellation cancellation) =>
      network.ecpSerial(endpoint, cancellation);

  String? _expected(RemoteDevice device, Map<String, Object?> probe) {
    final keys = [
      ...((probe['metadata'] as List?)?.cast<String>() ?? const []),
    ];
    for (final key in keys) {
      final value = device.metadata[key];
      if (value != null) {
        return value;
      }
    }
    final fallback = probe['fallbackMetadata'] as String?;
    return fallback == null ? null : device.metadata[fallback]?.split(':').last;
  }

  Future<String?> _observe(
    Map<String, Object?> probe,
    Uri endpoint,
    DiscoveryCancellation cancellation,
  ) => switch (probe['kind']) {
    'certificate' => network.certificate(endpoint, timeout: _probeTimeout),
    'peer-identity' => network.peerIdentity(
      endpoint.host,
      endpoint.port,
      timeout: _probeTimeout,
      reportNetworkFailure: true,
    ),
    _ => _serial(endpoint, cancellation),
  };

  static bool _same(
    Map<String, Object?> probe,
    String? observed,
    String expected,
  ) => probe['kind'] == 'ecp-serial'
      ? observed?.toLowerCase() == expected.toLowerCase()
      : observed == expected;
}
