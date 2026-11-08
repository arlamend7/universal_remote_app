import 'dart:async';

import 'package:remote_core/src/remote_base.dart';
import 'package:remote_core/src/device.dart';
import 'package:remote_core/src/discovery.dart';
import 'package:remote_core/src/errors/remote_exception.dart';
import 'package:remote_core/src/provider.dart';

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
  }) async {
    if (timeout <= Duration.zero) {
      throw ArgumentError('Discovery timeout must be positive.');
    }
    final devices = <String, RemoteDevice>{};
    final failures = <DiscoveryFailure>[];
    await Future.wait(
      _providers.values.map(
        (provider) => _discoverProvider(
          provider,
          timeout,
          cancellation,
          devices,
          failures,
          onDevices,
        ),
      ),
    );
    return DiscoveryResult(devices.values, failures);
  }

  Future<void> _discoverProvider(
    DeviceProvider provider,
    Duration timeout,
    DiscoveryCancellation? parent,
    Map<String, RemoteDevice> devices,
    List<DiscoveryFailure> failures,
    void Function(List<RemoteDevice>)? onDevices,
  ) async {
    final token = DiscoveryCancellation();
    void publish(List<RemoteDevice> found) {
      if (token.isCancelled || (parent?.isCancelled ?? false)) {
        return;
      }
      final before = devices.length;
      _mergeDevices(provider.id, found, devices);
      if (devices.length != before) {
        onDevices?.call(List.unmodifiable(devices.values));
      }
    }

    try {
      final found = await _responses(
        provider,
        token,
        parent,
        (device) => publish([device]),
      ).timeout(timeout);
      publish(found);
    } catch (error) {
      failures.add(DiscoveryFailure(provider.id, error));
    } finally {
      token.cancel();
    }
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

  void _mergeDevices(
    String provider,
    List<RemoteDevice> found,
    Map<String, RemoteDevice> devices,
  ) {
    for (final device in found) {
      devices.putIfAbsent('$provider:${device.id}', () => device);
    }
  }
}
