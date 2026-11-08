import 'dart:io';

import 'package:remote_core/src/remote_base.dart';
import 'package:remote_core/src/device.dart';

import '../../providers/services/provider_registry.dart';

/// Learns for a current authenticated session; manual configuration always wins.
final class DeviceWakeLearner {
  DeviceWakeLearner({
    required this.lookup,
    required this.update,
    required this.registry,
    required this.resolver,
    required this.normalizeMacAddress,
  });
  final RemoteDevice? Function(String id) lookup;
  final Future<void> Function(
    String id,
    RemoteDevice? Function(RemoteDevice) change,
  )
  update;
  final String? Function(String?) normalizeMacAddress;
  final ProviderRegistry registry;
  final HardwareAddressResolver resolver;
  static bool wasLearned(RemoteDevice device) => const {
    'localNeighbor',
    'television',
  }.contains(device.metadata['macAddressSource']);

  bool _manual(RemoteDevice device) =>
      (device.metadata['macAddress']?.isNotEmpty ?? false) &&
      !wasLearned(device);

  bool _needsLookup(RemoteDevice device) {
    if (!registry.supportsWake(device)) {
      return false;
    }
    return device.metadata['macAddressSource'] != null ||
        !registry.canWake(device);
  }

  Future<void> learn(
    RemoteBase controller,
    RemoteDevice device, {
    required bool Function() isCurrent,
  }) async {
    try {
      await _learn(controller, device, isCurrent);
    } catch (_) {
      // Optional lookup/storage failures never invalidate a paired connection.
    }
  }

  Future<void> _learn(
    RemoteBase controller,
    RemoteDevice device,
    bool Function() isCurrent,
  ) async {
    final current = lookup(device.id);
    final host = device.endpoints.firstOrNull?.host;
    if (!isCurrent() ||
        current == null ||
        _manual(current) ||
        host == null ||
        !_needsLookup(current)) {
      return;
    }
    final address = InternetAddress.tryParse(host);
    if (address == null || address.type != InternetAddressType.IPv4) {
      return;
    }
    final (detected, source) = await _detect(controller, address, isCurrent);
    if (detected == null) {
      return;
    }
    await update(
      device.id,
      (latest) => _updated(latest, detected, source, host, isCurrent),
    );
  }

  RemoteDevice? _updated(
    RemoteDevice latest,
    DeviceWakeAddress detected,
    String source,
    String host,
    bool Function() isCurrent,
  ) {
    if (!isCurrent() ||
        _manual(latest) ||
        latest.endpoints.firstOrNull?.host != host) {
      return null;
    }
    final previous = latest.metadata;
    final broadcast = detected.broadcastAddress;
    final canSetBroadcast =
        broadcast != null &&
        (previous['broadcastAddress'] == null ||
            previous['broadcastAddressSource'] == 'televisionSubnet');
    final broadcastChanged =
        canSetBroadcast && broadcast != previous['broadcastAddress'];
    if (previous['macAddress'] == detected.macAddress && !broadcastChanged) {
      return null;
    }
    return copyDevice(
      latest,
      metadata: {
        ...previous,
        'macAddress': detected.macAddress,
        'macAddressSource': source,
        'macAddressLearnedAt': DateTime.now().toUtc().toIso8601String(),
        if (canSetBroadcast) 'broadcastAddress': broadcast,
        if (canSetBroadcast) 'broadcastAddressSource': 'televisionSubnet',
      },
    );
  }

  Future<(DeviceWakeAddress?, String)> _detect(
    RemoteBase controller,
    InternetAddress address,
    bool Function() isCurrent,
  ) async {
    final reported = await _reported(controller);
    if (reported != null) {
      return (reported, 'television');
    }
    if (!isCurrent()) {
      return (null, 'localNeighbor');
    }
    final detected = await resolver
        .resolve(address)
        .timeout(const Duration(seconds: 3));
    final mac = normalizeMacAddress(detected);
    return (mac == null ? null : DeviceWakeAddress(mac), 'localNeighbor');
  }

  Future<DeviceWakeAddress?> _reported(RemoteBase controller) async {
    if (controller is! DeviceWakeAddressSource) {
      return null;
    }
    try {
      final source = controller as DeviceWakeAddressSource;
      final value = await source.readWakeAddress().timeout(
        const Duration(seconds: 4),
      );
      final mac = normalizeMacAddress(value?.macAddress);
      if (mac == null) {
        return null;
      }
      return DeviceWakeAddress(mac, broadcastAddress: value?.broadcastAddress);
    } catch (_) {
      return null;
    }
  }
}
