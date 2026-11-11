import 'package:remote_network/remote_network.dart';

import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';

import '../../providers/lg_web_os_provider.dart';
import '../functions/lg_web_os_endpoint.dart';

final class LgManualDeviceFactory {
  LgManualDeviceFactory(this.provider);
  final LgWebOsProvider provider;
  RemoteDevice create({
    required String address,
    required String name,
    required bool legacy,
    required bool allowInsecurePointer,
    String? certificate,
    String? mac,
    String? broadcast,
    RemoteDevice? existing,
  }) {
    final endpoint = lgWebOsEndpoint(address, secure: !legacy);
    _validateName(name);
    _validateCertificate(certificate);
    _validateMac(mac);
    _validateBroadcast(broadcast);
    final base =
        existing ??
        provider.manualDevice(
          address,
          profileId: newProfileId(),
          name: name.trim(),
          legacy: legacy,
        );
    final metadata = _metadata(
      base,
      legacy || allowInsecurePointer,
      certificate,
      mac,
      broadcast,
    );
    return copyDevice(
      base,
      name: name.trim(),
      endpoints: [endpoint],
      metadata: metadata,
    );
  }

  void _validateName(String name) {
    if (name.trim().isNotEmpty) {
      return;
    }
    throw const RemoteException('name', 'Enter a name for the TV.');
  }

  void _validateCertificate(String? certificate) {
    if (certificate == null || certificate.trim().isEmpty) {
      return;
    }
    try {
      if (base64Decode(certificate.trim()).isNotEmpty) {
        return;
      }
    } on FormatException {
      _invalidCertificate();
    }
    _invalidCertificate();
  }

  Never _invalidCertificate() => throw const RemoteException(
    'certificate',
    'Enter a valid base64 DER certificate, verified outside this connection.',
  );
  void _validateMac(String? mac) {
    if (mac == null || mac.trim().isEmpty) {
      return;
    }
    wakePacket(mac.trim());
  }

  void _validateBroadcast(String? broadcast) {
    if (broadcast == null || broadcast.trim().isEmpty) {
      return;
    }
    if (InternetAddress.tryParse(broadcast.trim())?.type ==
        InternetAddressType.IPv4) {
      return;
    }
    throw const RemoteException(
      'broadcast',
      'Enter a numeric IPv4 broadcast address.',
    );
  }

  Map<String, String> _metadata(
    RemoteDevice device,
    bool insecure,
    String? certificate,
    String? mac,
    String? broadcast,
  ) {
    final result = Map<String, String>.from(device.metadata)
      ..['allowInsecure'] = '$insecure';
    _replace(result, 'trustedCertificateDer', certificate);
    if (normalizeMacAddress(mac) !=
        normalizeMacAddress(device.metadata['macAddress'])) {
      result.remove('macAddressSource');
      result.remove('macAddressLearnedAt');
    }
    _replace(result, 'macAddress', normalizeMacAddress(mac));
    if (broadcast?.trim() != device.metadata['broadcastAddress']) {
      result.remove('broadcastAddressSource');
    }
    _replace(result, 'broadcastAddress', broadcast);
    return result;
  }

  void _replace(Map<String, String> metadata, String key, String? value) {
    metadata.remove(key);
    if (value == null || value.trim().isEmpty) {
      return;
    }
    metadata[key] = value.trim();
  }
}
