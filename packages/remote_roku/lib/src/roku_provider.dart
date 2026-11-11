import 'dart:io';

import 'package:remote_core/remote_core.dart';

import 'roku_controller.dart';
import 'roku_ecp_client.dart';
import 'roku_endpoint.dart';
import 'roku_identifier.dart';

final class RokuProvider implements ManualDeviceProvider, DeviceWakeProvider {
  const RokuProvider({this.bindings});

  final DriverBindingsLookup? bindings;

  String get id => RokuIdentifier.providerId;
  bool supports(RemoteDevice device) => device.providerId == id;

  ProviderDefinition<RokuController> get definition => ProviderDefinition(
    identifier: const RokuIdentifier(),
    createController: createController,
    manualSetup: this,
    wake: this,
    supportsManagedBindings: true,
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
    return RokuController(
      device,
      RokuEcpClient(endpoint),
      bindings: bindings?.call(device),
    );
  }

  /// A Roku TV that reports power control is sent the PowerOn key while it is
  /// in network standby. Roku's official key list has PowerOff but no PowerOn,
  /// so this is unverified and may be ignored. Streaming players cannot wake.
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
