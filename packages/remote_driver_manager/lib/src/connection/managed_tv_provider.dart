import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';
import 'package:remote_network/remote_network.dart';

import 'managed_driver_service.dart';
import 'managed_tv_controller.dart';

final class ManagedTvProvider
    implements ProviderIdentifier, ManualDeviceProvider, AddressIdentifier {
  const ManagedTvProvider(this.id, this._drivers);

  @override
  final String id;
  final ManagedDriverService _drivers;

  ProviderDefinition<ManagedTvController> get definition => ProviderDefinition(
    identifier: this,
    createController: (device) => ManagedTvController(device, _drivers),
    manualSetup: this,
  );

  Iterable<({DriverManifest manifest, DriverDiscoveryRules rules})>
  get _descriptions => _drivers.descriptions(id);

  @override
  String get label => 'Custom provider';

  @override
  DiscoveryRequirements get requirements {
    final targets = <DiscoveryProtocol, Set<String>>{};
    for (final description in _descriptions) {
      _addTargets(targets, description.rules.requirements);
    }
    return DiscoveryRequirements(targets);
  }

  static void _addTargets(
    Map<DiscoveryProtocol, Set<String>> targets,
    DiscoveryRequirements requirements,
  ) {
    for (final entry in requirements.targets.entries) {
      targets.putIfAbsent(entry.key, () => {}).addAll(entry.value);
    }
  }

  @override
  Future<ProviderMatch?> identify(
    DiscoveryObservation observation,
    DiscoveryCancellation cancellation,
  ) async {
    final host = observation.endpoint?.host;
    if (cancellation.isCancelled ||
        host == null ||
        !isLocalProbeAddress(host)) {
      return null;
    }
    final description = _descriptions.where((entry) {
      final services = entry.rules.requirements.targets[observation.protocolId];
      return services?.any(
            (service) =>
                service.toLowerCase() == observation.serviceType.toLowerCase(),
          ) ==
          true;
    }).firstOrNull;
    if (description == null) {
      return null;
    }
    final device = _device(
      description,
      host,
      observation.metadata['friendlyname'],
      model: observation.metadata['modelname'],
    );
    return ProviderMatch(
      ConnectionProfile(device, confirmed: true),
      observation,
    );
  }

  @override
  Future<bool> recognizesAddress(
    String address,
    DiscoveryCancellation cancellation,
  ) async {
    final targets = requirements.targets[DiscoveryProtocol.ssdp] ?? const {};
    final matches = await Future.wait(
      targets
          .take(8)
          .map((target) => probeSsdpAddress(address, target, cancellation)),
    );
    return matches.contains(true);
  }

  @override
  String get manualSetupLabel => _descriptions.firstOrNull?.manifest.name ?? id;

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
    final description = _descriptions.firstOrNull;
    if (description == null || legacy || allowInsecurePointer) {
      throw const FormatException('A compatible secure TV driver is required.');
    }
    final host = address.trim();
    final next = _device(description, host, name);
    if (existing == null) {
      return next;
    }
    return copyDevice(existing, name: next.name, endpoints: next.endpoints);
  }

  RemoteDevice _device(
    ({DriverManifest manifest, DriverDiscoveryRules rules}) description,
    String host,
    String? name, {
    String? model,
  }) {
    final label = name?.trim();
    return RemoteDevice(
      id: '$id:$host',
      name: label == null || label.isEmpty ? description.manifest.name : label,
      providerId: id,
      manufacturer: description.manifest.manufacturer,
      model: model,
      category: DeviceCategory.television,
      endpoints: [description.rules.endpoint(host)],
      stableIdentity: false,
    );
  }

  @override
  DeviceNetworkConfiguration networkConfiguration(RemoteDevice device) =>
      DeviceNetworkConfiguration(
        address: device.endpoints.firstOrNull?.host ?? '',
      );
}
