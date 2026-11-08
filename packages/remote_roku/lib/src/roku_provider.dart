import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import 'roku_controller.dart';
import 'roku_ecp_client.dart';
import 'roku_endpoint.dart';

final class RokuProvider implements DeviceProvider, ManualDeviceProvider {
  const RokuProvider({this.discovery = const SsdpDiscovery()});

  static const providerId = 'roku.ecp';
  static const service = 'roku:ecp';
  final SsdpDiscovery discovery;

  @override
  String get id => providerId;
  @override
  bool supports(RemoteDevice device) => device.providerId == id;

  @override
  Future<List<RemoteDevice>> discover(
    DiscoveryCancellation cancellation,
  ) async {
    if (cancellation.isCancelled) {
      return [];
    }
    final replies = await discovery.search(
      service,
      cancelled: cancellation.whenCancelled,
    );
    if (cancellation.isCancelled) {
      return [];
    }
    return DeviceIdentity.unique(
      replies.map(_device).whereType<RemoteDevice>(),
    );
  }

  RemoteDevice? _device(SsdpAdvertisement reply) {
    final location = reply.location;
    final serial = RegExp(
      r'^uuid:roku:ecp:([a-z0-9-]+)$',
      caseSensitive: false,
    ).firstMatch(reply.identity)?.group(1);
    if (reply.serviceType.toLowerCase() != service ||
        serial == null ||
        !isRokuLanAddress(reply.source) ||
        location == null ||
        location != rokuEndpoint(reply.source.address).replace(path: '/') &&
            location != rokuEndpoint(reply.source.address)) {
      return null;
    }
    return RemoteDevice(
      id: '$providerId:${serial.toLowerCase()}',
      name: 'Roku ($serial)',
      providerId: id,
      manufacturer: 'Roku',
      category: DeviceCategory.mediaPlayer,
      endpoints: [rokuEndpoint(reply.source.address)],
      metadata: {'usn': reply.identity, 'rokuSerial': serial},
    );
  }

  @override
  RemoteBase createController(RemoteDevice device) {
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
