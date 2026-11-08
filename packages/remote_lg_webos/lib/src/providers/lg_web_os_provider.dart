import 'package:remote_core/remote_core.dart';

import '../connection/models/lg_manual_device_factory.dart';

import 'package:remote_lg_webos/src/connection/functions/lg_web_os_endpoint.dart';
import 'package:remote_lg_webos/src/connection/models/lg_connection_options.dart';
import 'package:remote_lg_webos/src/devices/services/lg_device_controller.dart';
import 'package:remote_lg_webos/src/discovery/constants/lg_service_type.dart';
import 'package:remote_network/remote_network.dart';

final class LgWebOsProvider
    implements
        DeviceProvider,
        DeviceWakeProvider,
        IncrementalDiscoveryProvider,
        ManualDeviceProvider,
        DeviceConnectionPolicy {
  LgWebOsProvider({
    required this.credentials,
    this.discovery = const SsdpDiscovery(),
    this.options = const LgConnectionOptions(),
    TransportConnector? connector,
  }) : _connector = connector;
  final CredentialStore credentials;
  final SsdpDiscovery discovery;
  final LgConnectionOptions options;
  final TransportConnector? _connector;
  @override
  String get manualSetupLabel => 'LG webOS';

  @override
  bool get showsAdvancedSetup => true;

  @override
  ManualDeviceFactory get manualDeviceFactory =>
      LgManualDeviceFactory(this).create;

  @override
  DeviceNetworkConfiguration networkConfiguration(RemoteDevice device) =>
      DeviceNetworkConfiguration(
        address: device.endpoints.firstOrNull?.host ?? '',
        certificate: device.metadata['trustedCertificateDer'] ?? '',
        mac: device.metadata['macAddress'] ?? '',
        broadcast: device.metadata['broadcastAddress'] ?? '',
        legacy: device.endpoints.firstOrNull?.scheme == 'ws',
        allowInsecurePointer: device.metadata['allowInsecure'] == 'true',
      );

  @override
  bool sameConnection(RemoteDevice previous, RemoteDevice next) => const [
    'trustedCertificateDer',
    'allowInsecure',
    'macAddress',
    'broadcastAddress',
  ].every((key) => previous.metadata[key] == next.metadata[key]);

  @override
  bool canRetryAfterWake(Object error) =>
      error is RemoteException &&
      const {
        'network',
        'networkAccess',
        'connectionRefused',
        'timeout',
      }.contains(error.code);

  @override
  DeviceCategory get category => DeviceCategory.television;

  @override
  bool canReviewCertificate(RemoteDevice device, String? errorCode) =>
      errorCode == 'tls' && device.endpoints.firstOrNull?.scheme == 'wss';

  @override
  RemoteDevice trustCertificate(RemoteDevice device, String certificate) =>
      copyDevice(
        device,
        metadata: {...device.metadata, 'trustedCertificateDer': certificate},
      );

  @override
  RemoteDevice mergeDiscovered(RemoteDevice saved, RemoteDevice discovered) {
    final previous = saved.endpoints.firstOrNull;
    final current = discovered.endpoints.firstOrNull;
    return copyDevice(
      discovered,
      name: saved.name,
      metadata: {...discovered.metadata, ...saved.metadata},
      endpoints: previous == null || current == null
          ? discovered.endpoints
          : [previous.replace(host: current.host)],
    );
  }

  @override
  bool canWakeDevice(RemoteDevice device) =>
      supports(device) &&
      normalizeMacAddress(
            device.metadata['macAddress'] ?? options.macAddress,
          ) !=
          null;
  @override
  Future<void> wakeDevice(RemoteDevice device) async {
    if (!canWakeDevice(device)) {
      throw const RemoteException(
        'wakeUnavailable',
        'Configure a verified TV MAC address and enable network wake first.',
      );
    }
    await sendWakeOnLan(
      normalizeMacAddress(device.metadata['macAddress'] ?? options.macAddress)!,
      broadcast:
          device.metadata['broadcastAddress'] ?? options.broadcastAddress,
    );
  }

  @override
  String get id => 'lg.webos';
  @override
  bool supports(RemoteDevice device) => device.providerId == id;
  @override
  Future<List<RemoteDevice>> discover(DiscoveryCancellation cancellation) =>
      _discover(cancellation);

  @override
  Future<List<RemoteDevice>> discoverIncrementally(
    DiscoveryCancellation cancellation,
    void Function(RemoteDevice) onDevice,
  ) => _discover(cancellation, onDevice: onDevice);

  Future<List<RemoteDevice>> _discover(
    DiscoveryCancellation cancellation, {
    void Function(RemoteDevice)? onDevice,
  }) async {
    if (cancellation.isCancelled) {
      return [];
    }
    final responses = await discovery.search(
      lgServiceType,
      cancelled: cancellation.whenCancelled,
      onAdvertisement: onDevice == null
          ? null
          : (item) => onDevice(_device(item)),
    );
    return responses.map(_device).toList();
  }

  RemoteDevice _device(SsdpAdvertisement item) => RemoteDevice(
    id: '$id:${item.identity}',
    name: item.headers['friendlyname'] ?? 'LG webOS TV',
    providerId: id,
    manufacturer: 'LG',
    model: item.headers['modelname'],
    category: DeviceCategory.television,
    endpoints: [lgWebOsEndpoint(item.source.address)],
    metadata: {...item.headers, 'discoveredAddress': item.source.address},
  );

  /// A user-generated profile ID is mandatory: IP addresses are endpoints,
  /// not permanent identities. The application persists this profile ID.
  RemoteDevice manualDevice(
    String address, {
    required String profileId,
    String name = 'LG TV',
    bool legacy = false,
  }) => RemoteDevice(
    id: '$id:profile:$profileId',
    name: name,
    providerId: id,
    manufacturer: 'LG',
    category: DeviceCategory.television,
    stableIdentity: false,
    pairingState: PairingState.unpaired,
    endpoints: [lgWebOsEndpoint(address, secure: !legacy)],
    metadata: {'identitySource': 'userProfile'},
  );
  @override
  LgDeviceController createController(RemoteDevice device) {
    if (!supports(device)) {
      throw const RemoteException(
        'provider',
        'This is not an LG webOS device.',
      );
    }
    final configured = LgConnectionOptions(
      allowInsecure:
          device.metadata['allowInsecure'] == 'true' || options.allowInsecure,
      trustedCertificateDer:
          device.metadata['trustedCertificateDer'] ??
          options.trustedCertificateDer,
      macAddress: device.metadata['macAddress'] ?? options.macAddress,
      broadcastAddress:
          device.metadata['broadcastAddress'] ?? options.broadcastAddress,
    );
    return LgDeviceController(
      device: device,
      credentials: credentials,
      connector:
          _connector ??
          ((uri) => IoWebSocketTransport.connect(
            uri,
            trustedCertificateDer: configured.trustedCertificateDer,
          )),
      options: configured,
    );
  }
}
