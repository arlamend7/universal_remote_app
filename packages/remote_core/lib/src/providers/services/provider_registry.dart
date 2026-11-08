import 'dart:async';

import 'package:remote_core/src/remote_base.dart';
import 'package:remote_core/src/device.dart';
import 'package:remote_core/src/discovery.dart';
import 'package:remote_core/src/errors/remote_exception.dart';
import 'package:remote_core/src/provider.dart';

import '../models/discovery_status.dart';
import '../models/provider_discovery_status.dart';

final class ProviderRegistry {
  final Map<String, DeviceProvider> _providers = {};
  void register(DeviceProvider provider) {
    if (provider.id.isEmpty || _providers.containsKey(provider.id)) {
      throw ArgumentError('Provider ID must be unique and nonempty.');
    }
    _providers[provider.id] = provider;
  }

  DeviceProvider providerFor(RemoteDevice device) {
    final explicit = _providers[device.providerId];
    if (explicit != null && explicit.supports(device)) {
      return explicit;
    }
    final candidates = _providers.values
        .where((p) => p.supports(device))
        .toList();
    if (candidates.length != 1) {
      throw const RemoteException(
        'provider',
        'No unique compatible provider was found.',
      );
    }
    return candidates.single;
  }

  DeviceNetworkConfiguration networkConfiguration(RemoteDevice device) =>
      _extension<ManualDeviceProvider>(device)?.networkConfiguration(device) ??
      const DeviceNetworkConfiguration();

  Map<String, ManualDeviceSetup> get manualSetups => {
    for (final provider in _providers.values)
      if (provider is ManualDeviceProvider)
        provider.id: _manualSetup(provider as ManualDeviceProvider),
  };

  ManualDeviceSetup _manualSetup(ManualDeviceProvider provider) => (
    label: provider.manualSetupLabel,
    showsAdvancedSetup: provider.showsAdvancedSetup,
    factory: provider.manualDeviceFactory,
  );

  RemoteDevice createManualDevice({
    required String address,
    required String name,
    required bool legacy,
    required bool allowInsecurePointer,
    String? certificate,
    String? mac,
    String? broadcast,
    RemoteDevice? existing,
  }) {
    final provider = existing == null
        ? _onlyManualProvider()
        : _extension<ManualDeviceProvider>(existing);
    if (provider == null) {
      throw const RemoteException(
        'setup',
        'Choose a provider that supports manual setup.',
      );
    }
    return provider.manualDeviceFactory(
      address: address,
      name: name,
      legacy: legacy,
      allowInsecurePointer: allowInsecurePointer,
      certificate: certificate,
      mac: mac,
      broadcast: broadcast,
      existing: existing,
    );
  }

  ManualDeviceProvider? _onlyManualProvider() {
    final candidates = _providers.values
        .whereType<ManualDeviceProvider>()
        .toList();
    return candidates.length == 1 ? candidates.single : null;
  }

  bool supportsWake(RemoteDevice device) =>
      _extension<DeviceWakeProvider>(device) != null;

  bool canWake(RemoteDevice device) =>
      _extension<DeviceWakeProvider>(device)?.canWakeDevice(device) ?? false;

  Future<void> wake(RemoteDevice device) async {
    final provider = _extension<DeviceWakeProvider>(device);
    if (provider == null || !provider.canWakeDevice(device)) {
      throw const RemoteException(
        'wakeUnavailable',
        'Remote wake is unavailable for this device.',
      );
    }
    await provider.wakeDevice(device);
  }

  bool sameConnection(RemoteDevice previous, RemoteDevice next) =>
      previous.id == next.id &&
      previous.providerId == next.providerId &&
      _sameEndpoints(previous.endpoints, next.endpoints) &&
      (_extension<DeviceConnectionPolicy>(next)
              ?.sameConnection(previous, next) ??
          true);

  bool _sameEndpoints(List<Uri> first, List<Uri> second) {
    if (first.length != second.length) {
      return false;
    }
    return Iterable<int>.generate(first.length)
        .every((index) => first[index] == second[index]);
  }

  bool canRetryAfterWake(RemoteDevice device, Object error) =>
      _extension<DeviceConnectionPolicy>(device)?.canRetryAfterWake(error) ??
      false;

  DeviceCategory categoryFor(String providerId) {
    final provider = _providers[providerId];
    return provider is DeviceConnectionPolicy
        ? (provider as DeviceConnectionPolicy).category
        : DeviceCategory.unknown;
  }

  bool canReviewCertificate(RemoteDevice device, String? errorCode) =>
      _extension<DeviceConnectionPolicy>(device)
          ?.canReviewCertificate(device, errorCode) ??
      false;

  RemoteDevice trustCertificate(RemoteDevice device, String certificate) {
    final policy = _extension<DeviceConnectionPolicy>(device);
    if (policy == null) {
      throw const RemoteException(
        'certificate',
        'Certificate review is unavailable.',
      );
    }
    return policy.trustCertificate(device, certificate);
  }

  RemoteDevice mergeDiscovered(RemoteDevice saved, RemoteDevice discovered) =>
      _extension<DeviceConnectionPolicy>(discovered)
          ?.mergeDiscovered(saved, discovered) ??
      copyDevice(
        discovered,
        name: saved.name,
        metadata: {...discovered.metadata, ...saved.metadata},
      );

  T? _extension<T>(RemoteDevice device) {
    try {
      final provider = providerFor(device);
      return provider is T ? provider as T : null;
    } on RemoteException {
      return null;
    }
  }

  RemoteBase createController(RemoteDevice device) =>
      providerFor(device).createController(device);

  Future<DiscoveryResult> discover({
    Duration timeout = const Duration(seconds: 6),
    DiscoveryCancellation? cancellation,
    void Function(List<RemoteDevice>)? onDevices,
    void Function(ProviderDiscoveryStatus)? onStatus,
  }) async {
    if (timeout <= Duration.zero) {
      throw ArgumentError('Discovery timeout must be positive.');
    }
    if (cancellation?.isCancelled ?? false) {
      return DiscoveryResult([], []);
    }
    final devices = <RemoteDevice>[];
    final outcomes = await Future.wait(
      _providers.values.map(
        (provider) => _discoverProvider(
          provider,
          timeout,
          cancellation,
          (device) => _publishDevice(device, devices, onDevices),
          onStatus,
        ),
      ),
    );
    return DiscoveryResult(
      devices,
      outcomes.map((outcome) => outcome.failure).whereType<DiscoveryFailure>(),
    );
  }

  Future<ProviderDiscoveryStatus> _discoverProvider(
    DeviceProvider provider,
    Duration timeout,
    DiscoveryCancellation? parent,
    void Function(RemoteDevice) onDevice,
    void Function(ProviderDiscoveryStatus)? onStatus,
  ) async {
    final timer = Stopwatch()..start();
    final token = DiscoveryCancellation();
    final devices = <RemoteDevice>[];
    void publish(RemoteDevice device) {
      if (token.isCancelled || (parent?.isCancelled ?? false)) {
        return;
      }
      if (_addUnique(device, devices)) {
        onDevice(device);
      }
    }

    onStatus?.call(
      ProviderDiscoveryStatus(
        providerId: provider.id,
        status: DiscoveryStatus.searching,
      ),
    );
    DiscoveryFailure? failure;
    try {
      final found = await _responses(
        provider,
        token,
        parent,
        publish,
      ).timeout(timeout);
      found.forEach(publish);
    } catch (error) {
      failure = DiscoveryFailure(provider.id, error);
    } finally {
      token.cancel();
    }
    final cancelled = parent?.isCancelled ?? false;
    final outcome = ProviderDiscoveryStatus(
      providerId: provider.id,
      status: _status(cancelled, devices.isNotEmpty, failure != null),
      duration: timer.elapsed,
      deviceCount: devices.length,
      failure: cancelled ? null : failure,
      observations: token.observations,
    );
    onStatus?.call(outcome);
    return outcome;
  }

  DiscoveryStatus _status(bool cancelled, bool hasDevices, bool failed) {
    if (cancelled) {
      return DiscoveryStatus.cancelled;
    }
    if (failed) {
      return hasDevices
          ? DiscoveryStatus.partialSuccess
          : DiscoveryStatus.failed;
    }
    return hasDevices ? DiscoveryStatus.success : DiscoveryStatus.empty;
  }

  Future<List<RemoteDevice>> _responses(
    DeviceProvider provider,
    DiscoveryCancellation token,
    DiscoveryCancellation? parent,
    void Function(RemoteDevice) onDevice,
  ) => Future.any<List<RemoteDevice>>([
    provider is IncrementalDiscoveryProvider
        ? (provider as IncrementalDiscoveryProvider).discoverIncrementally(
            token,
            onDevice,
          )
        : provider.discover(token),
    if (parent != null) parent.whenCancelled.then((_) => <RemoteDevice>[]),
  ]);

  void _publishDevice(
    RemoteDevice device,
    List<RemoteDevice> devices,
    void Function(List<RemoteDevice>)? onDevices,
  ) {
    if (_addUnique(device, devices)) {
      onDevices?.call(List.unmodifiable(devices));
    }
  }

  bool _addUnique(RemoteDevice device, List<RemoteDevice> devices) {
    if (devices.any((existing) => DeviceIdentity.same(existing, device))) {
      return false;
    }
    devices.add(device);
    return true;
  }
}
