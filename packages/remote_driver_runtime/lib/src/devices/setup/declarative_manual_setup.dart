import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import 'manual_setup_rules.dart';

/// Creates and edits devices from a typed address using declared rules.
final class DeclarativeManualSetup implements ManualDeviceProvider {
  DeclarativeManualSetup(this.providerId, this.rules);

  final String providerId;
  final ManualSetupRules rules;

  @override
  String get manualSetupLabel => rules.label;

  @override
  bool get showsAdvancedSetup => rules.advanced;

  @override
  ManualDeviceFactory get manualDeviceFactory => _create;

  @override
  DeviceNetworkConfiguration networkConfiguration(RemoteDevice device) {
    final fields = rules.fields;
    final endpoint = device.endpoints.firstOrNull;
    final legacy = rules.legacyEndpoint != null;
    return DeviceNetworkConfiguration(
      address: endpoint?.host ?? '',
      certificate: fields.contains('certificate')
          ? device.metadata[DeviceMetadataKeys.trustedCertificateDer] ?? ''
          : '',
      mac: fields.contains('mac')
          ? device.metadata[DeviceMetadataKeys.macAddress] ?? ''
          : '',
      broadcast: fields.contains('broadcast')
          ? device.metadata[DeviceMetadataKeys.broadcastAddress] ?? ''
          : '',
      legacy: legacy && endpoint?.scheme == rules.legacyEndpoint!.scheme,
      allowInsecurePointer:
          legacy && device.metadata[rules.insecureMetadata] == 'true',
    );
  }

  RemoteDevice _create({
    required String address,
    required String name,
    required bool legacy,
    required bool allowInsecurePointer,
    String? certificate,
    String? mac,
    String? broadcast,
    RemoteDevice? existing,
  }) {
    final endpoint = _endpoint(
      address.trim(),
      legacy: legacy,
      insecure: legacy || allowInsecurePointer,
    );
    final label = _name(name);
    final metadata = _metadata(
      existing,
      legacy || allowInsecurePointer,
      certificate: _certificate(certificate),
      mac: _mac(mac),
      broadcast: _broadcast(broadcast),
    );
    return copyDevice(
      existing ?? _newDevice(label),
      name: label,
      endpoints: [endpoint],
      metadata: metadata,
    );
  }

  Uri _endpoint(
    String address, {
    required bool legacy,
    required bool insecure,
  }) {
    final secureOnly = rules.secureOnlyMessage;
    if (insecure && rules.legacyEndpoint == null && secureOnly != null) {
      throw FormatException(secureOnly);
    }
    if (!rules.address.accepts(address)) {
      throw FormatException(
        rules.message('address', 'Enter the TV’s local IP address.'),
      );
    }
    final host = InternetAddress.tryParse(address)!.address;
    final template = rules.legacyEndpoint;
    return legacy && template != null
        ? template.build(host)
        : rules.endpoint.build(host);
  }

  String _name(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    if (rules.requireName) {
      throw FormatException(rules.message('name', 'Enter a name for the TV.'));
    }
    return rules.defaultName;
  }

  RemoteDevice _newDevice(String name) {
    final profile = newProfileId();
    final template = rules.idTemplate;
    return RemoteDevice(
      id: template == null
          ? profile
          : template
                .replaceAll('{providerId}', providerId)
                .replaceAll('{profile}', profile),
      name: name,
      providerId: providerId,
      manufacturer: rules.manufacturer,
      category: rules.category,
      stableIdentity: false,
      pairingState: PairingState.unpaired,
      metadata: rules.metadata,
    );
  }

  Map<String, String> _metadata(
    RemoteDevice? existing,
    bool insecure, {
    String? certificate,
    String? mac,
    String? broadcast,
  }) {
    final previous = existing?.metadata ?? rules.metadata;
    final result = {...previous};
    _replace(
      result,
      'certificate',
      DeviceMetadataKeys.trustedCertificateDer,
      certificate,
    );
    _replace(result, 'mac', DeviceMetadataKeys.macAddress, mac);
    _replace(
      result,
      'broadcast',
      DeviceMetadataKeys.broadcastAddress,
      broadcast,
    );
    if (rules.fields.contains('mac') &&
        mac != normalizeMacAddress(previous[DeviceMetadataKeys.macAddress])) {
      result
        ..remove(DeviceMetadataKeys.macAddressSource)
        ..remove('macAddressLearnedAt');
    }
    if (rules.fields.contains('broadcast') &&
        broadcast != previous[DeviceMetadataKeys.broadcastAddress]) {
      result.remove('broadcastAddressSource');
    }
    final insecureKey = rules.insecureMetadata;
    return {...result, if (insecureKey != null) insecureKey: '$insecure'};
  }

  /// Only declared fields are edited; others keep learned values.
  void _replace(
    Map<String, String> metadata,
    String field,
    String key,
    String? value,
  ) {
    if (!rules.fields.contains(field)) {
      return;
    }
    metadata.remove(key);
    if (value != null) {
      metadata[key] = value;
    }
  }

  String? _certificate(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty || !rules.fields.contains('certificate')) {
      return null;
    }
    try {
      final bytes = base64Decode(text);
      if (bytes.isNotEmpty && bytes.length <= 16384) {
        return base64Encode(bytes);
      }
    } on FormatException {
      // Report a setup error without including the supplied certificate.
    }
    throw FormatException(
      rules.message('certificate', 'Enter a valid base64 DER certificate.'),
    );
  }

  String? _mac(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty || !rules.fields.contains('mac')) {
      return null;
    }
    final normalized = normalizeMacAddress(text);
    if (normalized == null) {
      throw FormatException(
        rules.message('mac', 'Enter a valid TV MAC address.'),
      );
    }
    return normalized;
  }

  String? _broadcast(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty || !rules.fields.contains('broadcast')) {
      return null;
    }
    if (InternetAddress.tryParse(text)?.type != InternetAddressType.IPv4) {
      throw FormatException(
        rules.message('broadcast', 'Enter an IPv4 broadcast address.'),
      );
    }
    return text;
  }
}
