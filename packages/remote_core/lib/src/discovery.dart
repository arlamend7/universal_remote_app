import 'dart:async';

import 'package:remote_core/src/device.dart';

/// Cooperative cancellation; providers must release discovery resources.
final class DiscoveryCancellation {
  final _cancelled = Completer<void>();
  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get whenCancelled => _cancelled.future;
  void cancel() {
    if (!_cancelled.isCompleted) {
      _cancelled.complete();
    }
  }
}

final class DiscoveryFailure {
  const DiscoveryFailure(this.providerId, this.error);
  final String providerId;
  final Object error;
}

final class DiscoveryResult {
  DiscoveryResult(
    Iterable<RemoteDevice> devices,
    Iterable<DiscoveryFailure> failures,
  ) : devices = List.unmodifiable(devices),
      failures = List.unmodifiable(failures);
  final List<RemoteDevice> devices;
  final List<DiscoveryFailure> failures;
}

/// Addresses are a fallback only when a permanent identity is missing.
abstract final class DeviceIdentity {
  static Set<String> keys(RemoteDevice device) {
    final values = <String>{};
    if (device.stableIdentity) {
      values.add('id:${device.providerId}:${device.id.toLowerCase()}');
    }
    final alias = device.metadata['discoveryProfileId'];
    if (alias != null) {
      values.add('id:${device.providerId}:${alias.toLowerCase()}');
    }
    for (final field in ['usn', 'udn', 'uuid', 'discoveryIdentity']) {
      final value = device.metadata[field]?.trim().toLowerCase();
      if (value != null && value.isNotEmpty) {
        values.add(
          'uuid:${value.split('::').first.replaceFirst(RegExp(r'^uuid:'), '')}',
        );
      }
    }
    final mac = device.metadata['macAddress']
        ?.replaceAll(RegExp(r'[^a-fA-F0-9]'), '')
        .toLowerCase();
    if (mac != null && mac.length == 12) {
      values.add('mac:$mac');
    }
    return values;
  }

  static bool same(RemoteDevice left, RemoteDevice right) {
    if (left.providerId == right.providerId && left.id == right.id) {
      return true;
    }
    final a = keys(left), b = keys(right);
    if (a.intersection(b).isNotEmpty) {
      return true;
    }
    if (left.providerId != right.providerId ||
        (left.stableIdentity && right.stableIdentity)) {
      return false;
    }
    // Do not merge conflicting UUIDs merely because a DHCP address was reused.
    final aUuid = a.where((key) => key.startsWith('uuid:')).toSet();
    final bUuid = b.where((key) => key.startsWith('uuid:')).toSet();
    if (aUuid.isNotEmpty && bUuid.isNotEmpty) {
      return false;
    }
    final hosts = left.endpoints.map((uri) => uri.host.toLowerCase()).toSet();
    return right.endpoints.any((uri) => hosts.contains(uri.host.toLowerCase()));
  }

  static List<RemoteDevice> unique(Iterable<RemoteDevice> devices) {
    final result = <RemoteDevice>[];
    for (final device in devices) {
      if (!result.any((existing) => same(existing, device))) {
        result.add(device);
      }
    }
    return result;
  }
}

/// Learns stable identity without changing profile IDs, credentials or trust.
final class DiscoveryProfiles {
  DiscoveryProfiles({required this.profiles, required this.update});
  final Iterable<RemoteDevice> Function() profiles;
  final Future<void> Function(
    String id,
    RemoteDevice? Function(RemoteDevice) change,
  )
  update;
  RemoteDevice? registered(RemoteDevice candidate) => profiles()
      .where((device) => DeviceIdentity.same(device, candidate))
      .firstOrNull;
  Map<String, String> _identity(RemoteDevice candidate) {
    final uuid =
        candidate.metadata['usn'] ??
        candidate.metadata['uuid'] ??
        candidate.metadata['udn'];
    return {
      if (uuid != null) 'discoveryIdentity': uuid,
      if (candidate.stableIdentity) 'discoveryProfileId': candidate.id,
    };
  }

  Future<void> remember(RemoteDevice candidate) async {
    final existing = registered(candidate);
    if (existing == null) {
      return;
    }
    final identity = _identity(candidate);
    await update(existing.id, (current) {
      if (identity.entries.every(
        (entry) => current.metadata[entry.key] == entry.value,
      )) {
        return null;
      }
      return copyDevice(current, metadata: {...current.metadata, ...identity});
    });
  }

  Future<void> updateAddress(RemoteDevice candidate) async {
    final existing = registered(candidate);
    final endpoint = candidate.endpoints.firstOrNull;
    if (existing == null || endpoint == null) {
      return;
    }
    await update(
      existing.id,
      (current) => copyDevice(
        current,
        endpoints: current.endpoints
            .map((old) => old.replace(host: endpoint.host))
            .toList(),
        metadata: {...current.metadata, ..._identity(candidate)},
      ),
    );
  }
}
