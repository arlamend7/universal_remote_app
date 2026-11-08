import 'package:flutter/foundation.dart';
import 'package:remote_core/remote_core.dart';

import '../ui_model.dart';

import 'dashboard_repository.dart';

final class DeviceGridsController implements DashboardStore {
  DeviceGridsController(this.repository);
  final DashboardRepository repository;
  final revision = ValueNotifier(0);
  Map<String, String> _dashboards = {};
  Future<void> _writes = Future.value();

  Future<void> initialize(Iterable<RemoteDevice> profiles) async {
    _dashboards = await repository.load();
    final migrated = {
      for (final device in profiles)
        if (!_dashboards.containsKey(device.id) && _legacyGrid(device) != null)
          device.id: _legacyGrid(device)!,
    };
    if (migrated.isEmpty) {
      return;
    }
    final combined = {..._dashboards, ...migrated};
    await repository.save(combined);
    _dashboards = combined;
  }

  @override
  GridLayout? forDevice(RemoteDevice device) =>
      _decode(_dashboards[device.id] ?? _legacyGrid(device));

  String? _legacyGrid(RemoteDevice device) {
    final raw = device.metadata['remoteGrid.v2'];
    return device.metadata['remoteGrid.active'] == 'true' &&
            _decode(raw) != null
        ? raw
        : null;
  }

  GridLayout? _decode(String? raw) {
    if (raw == null) {
      return null;
    }
    try {
      final layout = GridLayout.decode(raw);
      return GridGeometry.valid(layout.items) ? layout : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(RemoteDevice device, GridLayout layout) async {
    if (!GridGeometry.valid(layout.items)) {
      throw const RemoteException(
        'grid',
        'The layout contains overlapping or invalid controls.',
      );
    }
    final result = _writes.then((_) => _save(device.id, layout.encode()));
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    await result;
  }

  Future<void> _save(String deviceId, String layout) async {
    final next = {..._dashboards, deviceId: layout};
    await repository.save(next);
    _dashboards = next;
    revision.value++;
  }

  Future<void> dispose() async {
    await _writes;
    revision.dispose();
  }
}
