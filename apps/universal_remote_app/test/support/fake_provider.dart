import 'dart:async';

import 'fake_controller.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';

import 'test_device.dart';

class FakeProvider implements ProviderIdentifier {
  FakeProvider({
    this.fail = false,
    this.providerId = 'test',
    this.startupFailure,
    this.pairing = false,
    this.enableContentFeedback = true,
    this.enabledControls = false,
    this.wakeAddress,
    this.reportedManufacturer,
  });

  /// The manufacturer the controller learns from its session, if any.
  final String? reportedManufacturer;
  final bool fail;
  final String providerId;
  final RemoteException? startupFailure;
  final bool pairing;
  final bool enabledControls;
  final bool enableContentFeedback;
  final String? wakeAddress;
  FakeController? last;
  @override
  String get id => providerId;
  bool supports(RemoteDevice device) => device.providerId == id;

  @override
  String get label => 'Custom provider';

  String get service => 'fixture.$id';

  @override
  DiscoveryRequirements get requirements => DiscoveryRequirements({
    DiscoveryProtocol.ssdp: {service},
  });

  ProviderDefinition<RemoteBase> get definition => ProviderDefinition(
    identifier: this,
    createController: createController,
    wake: this is DeviceWakeProvider ? this as DeviceWakeProvider : null,
    manualSetup: this is ManualDeviceProvider
        ? this as ManualDeviceProvider
        : null,
    connection: this is DeviceConnectionPolicy
        ? this as DeviceConnectionPolicy
        : null,
  );

  final _observed = <RemoteDevice>[];

  Future<List<RemoteDevice>> discover(
    DiscoveryCancellation cancellation,
  ) async => [tv];

  Future<void> search(
    String service,
    DiscoveryCancellation cancellation,
    Future<void> Function(DiscoveryObservation) observe,
  ) async {
    final devices = await Future.any([
      discover(cancellation),
      cancellation.whenCancelled.then((_) => <RemoteDevice>[]),
    ]);
    _observed.clear();
    for (final device in devices) {
      if (cancellation.isCancelled) {
        return;
      }
      _observed.add(device);
      await observe(
        DiscoveryObservation(
          protocolId: DiscoveryProtocol.ssdp,
          serviceType: service,
          endpoint: device.endpoints.firstOrNull,
          metadata: {'index': '${_observed.length - 1}'},
        ),
      );
    }
  }

  @override
  Future<ProviderMatch?> identify(
    DiscoveryObservation observation,
    DiscoveryCancellation cancellation,
  ) async {
    if (observation.serviceType != service || cancellation.isCancelled) {
      return null;
    }
    final index = int.parse(observation.metadata['index']!);
    return ProviderMatch(
      ConnectionProfile(_observed[index], confirmed: true),
      observation,
    );
  }

  RemoteBase createController(RemoteDevice device) => last = FakeController(
    device.manufacturer == null && reportedManufacturer != null
        ? copyDevice(device, manufacturer: reportedManufacturer)
        : device,
    failure: fail,
    startupFailure: startupFailure,
    waitPairing: pairing,
    enabledControls: enabledControls,
    enableContentFeedback: enableContentFeedback,
    wakeAddress: wakeAddress,
  );
}
