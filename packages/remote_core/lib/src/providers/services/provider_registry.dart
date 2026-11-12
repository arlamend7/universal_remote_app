import 'package:remote_core/src/remote_base.dart';
import 'package:remote_core/src/device.dart';
import 'package:remote_core/src/errors/remote_exception.dart';
import 'package:remote_core/src/provider.dart';

import '../models/provider_definition.dart';
import '../../discovery.dart';
import '../../discovery/address_identifier.dart';
import '../../discovery/is_local_probe_address.dart';

final class ProviderRegistry {
  final _definitions = <String, ProviderDefinition<RemoteBase>>{};

  Iterable<ProviderDefinition<RemoteBase>> get definitions =>
      _definitions.values;

  bool get canIdentifyAddresses => definitions.any(
    (definition) =>
        definition.manualSetup != null &&
        definition.identifier is AddressIdentifier,
  );

  Future<List<String>> identifyAddress(
    String address,
    DiscoveryCancellation cancellation,
  ) async {
    if (!isLocalProbeAddress(address)) {
      throw const FormatException('Enter a numeric local TV IP address.');
    }
    final results = await Future.wait([
      for (final definition in definitions)
        if (definition.manualSetup != null &&
            definition.identifier is AddressIdentifier)
          _identifyAddress(definition, address, cancellation),
    ]);
    return cancellation.isCancelled ? [] : results.whereType<String>().toList();
  }

  Future<String?> _identifyAddress(
    ProviderDefinition<RemoteBase> definition,
    String address,
    DiscoveryCancellation cancellation,
  ) async {
    final identifier = definition.identifier as AddressIdentifier;
    try {
      final matches = await identifier
          .recognizesAddress(address, cancellation)
          .timeout(const Duration(seconds: 4));
      return matches ? definition.id : null;
    } catch (_) {
      return null;
    }
  }

  bool isRegistered(String id) => _definitions.containsKey(id);

  void registerDefinition(ProviderDefinition<RemoteBase> definition) {
    _validateId(definition.id);
    _definitions[definition.id] = definition;
  }

  /// Replaces a provider's definition, for example after its integration
  /// data was refreshed; unknown providers are registered.
  void replaceDefinition(ProviderDefinition<RemoteBase> definition) {
    if (definition.id.trim().isEmpty) {
      throw ArgumentError('Provider ID must be nonempty.');
    }
    _definitions[definition.id] = definition;
  }

  void _validateId(String id) {
    if (id.trim().isEmpty || _definitions.containsKey(id)) {
      throw ArgumentError('Provider ID must be unique and nonempty.');
    }
  }

  ProviderDefinition<RemoteBase> providerFor(RemoteDevice device) {
    final definition = _definitions[device.providerId];
    if (definition == null) {
      throw const RemoteException(
        'provider',
        'The device integration is unavailable.',
      );
    }
    return definition;
  }

  DeviceNetworkConfiguration networkConfiguration(RemoteDevice device) =>
      _extension<ManualDeviceProvider>(device)?.networkConfiguration(device) ??
      const DeviceNetworkConfiguration();

  Map<String, ManualDeviceSetup> get manualSetups => {
    for (final definition in _definitions.values)
      if (definition.manualSetup case final setup?)
        definition.id: _manualSetup(setup),
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
    final candidates = [
      ..._definitions.values
          .map((definition) => definition.manualSetup)
          .whereType<ManualDeviceProvider>(),
    ];
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
    if (_definitions[device.providerId] case final definition?) {
      return [
        definition.manualSetup,
        definition.wake,
        definition.connection,
      ].whereType<T>().firstOrNull;
    }
    return null;
  }

  RemoteBase createController(RemoteDevice device) =>
      providerFor(device).createController(device);
}
