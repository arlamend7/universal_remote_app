import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import 'connection/samsung_endpoint.dart';
import 'discovery/samsung_identifier.dart';
import 'samsung_controller.dart';

final class SamsungProvider
    implements
        ManualDeviceProvider,
        DeviceConnectionPolicy,
        DeviceWakeProvider {
  const SamsungProvider({required this.credentials, this.bindings});

  final CredentialStore credentials;
  final DriverBindingsLookup? bindings;

  ProviderDefinition<SamsungController> get definition => ProviderDefinition(
    identifier: const SamsungIdentifier(),
    createController: _controller,
    manualSetup: this,
    connection: this,
    wake: this,
    supportsManagedBindings: true,
  );

  SamsungController _controller(RemoteDevice device) {
    final endpoint = device.endpoints.singleOrNull;
    if (endpoint == null ||
        !isLocalProbeAddress(endpoint.host) ||
        endpoint != samsungEndpoint(endpoint.host)) {
      throw const RemoteException(
        'setup',
        'Configure the Samsung TV’s local address.',
      );
    }
    return SamsungController(
      device,
      credentials,
      () => wakeDevice(device),
      canWakeDevice(device),
      bindings: bindings?.call(device),
    );
  }

  @override
  DeviceCategory get category => DeviceCategory.television;
  @override
  String get manualSetupLabel => 'Samsung Tizen';
  @override
  bool get showsAdvancedSetup => true;
  @override
  ManualDeviceFactory get manualDeviceFactory => _manualDevice;

  RemoteDevice _manualDevice({
    required String address,
    required String name,
    required bool legacy,
    required bool allowInsecurePointer,
    String? certificate,
    String? mac,
    String? broadcast,
    RemoteDevice? existing,
  }) {
    if (legacy || allowInsecurePointer) {
      throw const FormatException(
        'Samsung Tizen requires a secure connection.',
      );
    }
    final endpoint = samsungEndpoint(address.trim());
    final label = name.trim().isEmpty ? 'Samsung TV' : name.trim();
    final normalizedMac = normalizeMacAddress(mac);
    final pin = _pin(certificate);
    _validateWake(mac, normalizedMac, broadcast);
    final metadata = {...?existing?.metadata}
      ..remove('trustedCertificateDer')
      ..remove('macAddress')
      ..remove('broadcastAddress');
    if (normalizedMac != existing?.metadata['macAddress']) {
      metadata.remove('macAddressSource');
    }
    return copyDevice(
      existing ??
          RemoteDevice(
            id: newProfileId(),
            name: label,
            providerId: ProviderIdentity.samsungTizen.storageId,
            manufacturer: 'Samsung',
            category: category,
            stableIdentity: false,
          ),
      name: label,
      endpoints: [endpoint],
      metadata: {
        ...metadata,
        if (pin != null) 'trustedCertificateDer': pin,
        if (normalizedMac != null) 'macAddress': normalizedMac,
        if (broadcast != null && broadcast.trim().isNotEmpty)
          'broadcastAddress': broadcast.trim(),
      },
    );
  }

  void _validateWake(String? mac, String? normalized, String? broadcast) {
    if (mac != null && mac.trim().isNotEmpty && normalized == null) {
      throw const FormatException('Enter a valid Samsung TV MAC address.');
    }
    if (broadcast != null &&
        broadcast.trim().isNotEmpty &&
        InternetAddress.tryParse(broadcast.trim())?.type !=
            InternetAddressType.IPv4) {
      throw const FormatException('Enter an IPv4 broadcast address.');
    }
  }

  String? _pin(String? certificate) {
    if (certificate == null || certificate.trim().isEmpty) {
      return null;
    }
    try {
      final bytes = base64Decode(certificate.trim());
      if (bytes.isNotEmpty && bytes.length <= 16384) {
        return base64Encode(bytes);
      }
    } on FormatException {
      // Report a setup error without including the supplied certificate.
    }
    throw const FormatException('Enter a valid base64 DER certificate.');
  }

  @override
  DeviceNetworkConfiguration networkConfiguration(RemoteDevice device) =>
      DeviceNetworkConfiguration(
        address: device.endpoints.firstOrNull?.host ?? '',
        certificate: device.metadata['trustedCertificateDer'] ?? '',
        mac: device.metadata['macAddress'] ?? '',
        broadcast: device.metadata['broadcastAddress'] ?? '',
      );

  @override
  bool canReviewCertificate(RemoteDevice device, String? errorCode) =>
      errorCode == 'tls' && device.endpoints.singleOrNull?.scheme == 'wss';

  @override
  RemoteDevice trustCertificate(RemoteDevice device, String certificate) =>
      copyDevice(
        device,
        metadata: {
          ...device.metadata,
          'trustedCertificateDer': _pin(certificate)!,
        },
      );

  @override
  bool sameConnection(RemoteDevice previous, RemoteDevice next) =>
      previous.metadata['trustedCertificateDer'] ==
      next.metadata['trustedCertificateDer'];

  @override
  bool canRetryAfterWake(Object error) =>
      error is RemoteException &&
      const {'network', 'timeout'}.contains(error.code);

  @override
  RemoteDevice mergeDiscovered(RemoteDevice saved, RemoteDevice discovered) =>
      copyDevice(saved, endpoints: discovered.endpoints);

  @override
  bool canWakeDevice(RemoteDevice device) =>
      normalizeMacAddress(device.metadata['macAddress']) != null;

  @override
  Future<void> wakeDevice(RemoteDevice device) async {
    final mac = normalizeMacAddress(device.metadata['macAddress']);
    if (mac == null) {
      throw const RemoteException(
        'wakeUnavailable',
        'Configure the Samsung TV’s MAC address first.',
      );
    }
    await sendWakeOnLan(
      mac,
      broadcast: device.metadata['broadcastAddress'] ?? '255.255.255.255',
    );
  }
}
