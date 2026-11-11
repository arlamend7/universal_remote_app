import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import 'android_tv_controller.dart';
import 'discovery/android_tv_identifier.dart';

final class AndroidTvProvider
    implements ManualDeviceProvider, DeviceWakeProvider {
  const AndroidTvProvider({required this.credentials, this.bindings});

  final CredentialStore credentials;
  final DriverBindingsLookup? bindings;

  String get id => AndroidTvIdentifier.providerId;
  bool supports(RemoteDevice device) => device.providerId == id;

  ProviderDefinition<AndroidTvController> get definition => ProviderDefinition(
    identifier: const AndroidTvIdentifier(),
    createController: createController,
    manualSetup: this,
    wake: this,
    supportsManagedBindings: true,
  );

  AndroidTvController createController(RemoteDevice device) =>
      AndroidTvController(
        device,
        credentials,
        () => wakeDevice(device),
        canWakeDevice(device),
        bindings: bindings?.call(device),
      );

  /// Needs the TV's MAC address (learned after a connection) and network
  /// wake enabled on the TV.
  @override
  bool canWakeDevice(RemoteDevice device) =>
      supports(device) &&
      normalizeMacAddress(device.metadata['macAddress']) != null;

  @override
  Future<void> wakeDevice(RemoteDevice device) async {
    final mac = normalizeMacAddress(device.metadata['macAddress']);
    if (!supports(device) || mac == null) {
      throw const RemoteException(
        'wakeUnavailable',
        'The TV’s MAC address is not known yet. Connect once so it can be learned.',
      );
    }
    await sendWakeOnLan(
      mac,
      broadcast: device.metadata['broadcastAddress'] ?? '255.255.255.255',
    );
  }

  @override
  String get manualSetupLabel => 'Google TV / Android TV';

  @override
  bool get showsAdvancedSetup => false;

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
    final ip = InternetAddress.tryParse(address.trim());
    if (ip == null || ip.isLoopback || ip.isMulticast) {
      throw const FormatException('Enter the TV’s local IP address.');
    }
    if (legacy || allowInsecurePointer) {
      throw const FormatException('Android TV requires a secure connection.');
    }
    final endpoint = Uri(scheme: 'tls', host: ip.address, port: 6466);
    final label = name.trim().isEmpty ? 'Android TV' : name.trim();
    if (existing != null) {
      return copyDevice(existing, name: label, endpoints: [endpoint]);
    }
    return RemoteDevice(
      id: newProfileId(),
      name: label,
      providerId: id,
      category: DeviceCategory.television,
      endpoints: [endpoint],
      stableIdentity: false,
    );
  }

  @override
  DeviceNetworkConfiguration networkConfiguration(RemoteDevice device) =>
      DeviceNetworkConfiguration(
        address: device.endpoints.firstOrNull?.host ?? '',
      );
}
