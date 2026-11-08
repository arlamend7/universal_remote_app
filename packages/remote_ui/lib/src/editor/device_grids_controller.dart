import 'package:flutter/foundation.dart';
import 'package:remote_core/remote_core.dart';

import '../ui_model.dart';

import 'dashboard_repository.dart';

final class DeviceGridsController {
  DeviceGridsController(this.repository);
  final DashboardRepository repository;
  final revision = ValueNotifier(0);
  Map<String, String> _dashboards = {};
  Future<void> _writes = Future.value();

  Future<void> initialize() async {
    _dashboards = await repository.load();
  }

  GridLayout? forDevice(RemoteDevice device) => _decode(_dashboards[device.id]);

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
