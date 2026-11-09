import 'dart:io';

import 'package:remote_core/remote_core.dart';

import 'android_tv_controller.dart';
import 'discovery/android_tv_identifier.dart';

final class AndroidTvProvider implements ManualDeviceProvider {
  const AndroidTvProvider({required this.credentials});

  final CredentialStore credentials;

  String get id => AndroidTvIdentifier.providerId;
  bool supports(RemoteDevice device) => device.providerId == id;

  ProviderDefinition<AndroidTvController> get definition => ProviderDefinition(
    identifier: const AndroidTvIdentifier(),
    createController: createController,
    manualSetup: this,
  );

  AndroidTvController createController(RemoteDevice device) =>
      AndroidTvController(device, credentials);

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
