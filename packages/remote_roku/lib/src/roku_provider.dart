import 'dart:io';

import 'package:remote_core/remote_core.dart';

import 'roku_controller.dart';
import 'roku_ecp_client.dart';
import 'roku_endpoint.dart';
import 'roku_identifier.dart';

final class RokuProvider implements ManualDeviceProvider, DeviceWakeProvider {
  const RokuProvider();

  String get id => RokuIdentifier.providerId;
  bool supports(RemoteDevice device) => device.providerId == id;

  ProviderDefinition<RokuController> get definition => ProviderDefinition(
    identifier: const RokuIdentifier(),
    createController: createController,
    manualSetup: this,
    wake: this,
  );

  RokuController createController(RemoteDevice device) {
    final endpoint = device.endpoints.singleOrNull;
    if (!supports(device) ||
        endpoint == null ||
        !isRokuLanAddress(InternetAddress.tryParse(endpoint.host)) ||
        endpoint != rokuEndpoint(endpoint.host)) {
      throw const RemoteException(
        'setup',
        'Roku requires a local IPv4 address and its HTTP control port.',
      );
    }
    return RokuController(device, RokuEcpClient(endpoint));
  }

  /// A Roku TV that reports power control can be woken with the documented
  /// PowerOn key while it is in network standby. Streaming players cannot.
  @override
  bool canWakeDevice(RemoteDevice device) =>
      supports(device) && device.capabilities.contains(RemoteCapability.power);

  @override
  Future<void> wakeDevice(RemoteDevice device) async {
    final endpoint = device.endpoints.singleOrNull;
    if (!canWakeDevice(device) || endpoint == null) {
      throw const RemoteException(
        'wakeUnavailable',
        'This Roku has not reported TV power control.',
      );
    }
    await RokuEcpClient(endpoint).key('PowerOn');
  }

  @override
  String get manualSetupLabel => 'Roku (local HTTP)';
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
    if (ip == null || !isRokuLanAddress(ip)) {
      throw const FormatException('Enter the Roku’s local IPv4 address.');
    }
    final label = name.trim().isEmpty ? 'Roku' : name.trim();
    final endpoints = [rokuEndpoint(ip.address)];
    if (existing != null) {
      return copyDevice(existing, name: label, endpoints: endpoints);
    }
    return RemoteDevice(
      id: newProfileId(),
      name: label,
      providerId: id,
      manufacturer: 'Roku',
      category: DeviceCategory.mediaPlayer,
      endpoints: endpoints,
      stableIdentity: false,
    );
  }

  @override
  DeviceNetworkConfiguration networkConfiguration(RemoteDevice device) =>
      DeviceNetworkConfiguration(
        address: device.endpoints.firstOrNull?.host ?? '',
      );
}
