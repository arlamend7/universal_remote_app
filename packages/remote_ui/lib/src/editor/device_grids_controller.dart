import 'package:flutter/foundation.dart';
import 'package:remote_core/remote_core.dart';

import '../ui_model.dart';

import 'dashboard_repository.dart';

final class DeviceGridsController {
  DeviceGridsController(this.repository, {this.deviceKey});
  final String Function(RemoteDevice)? deviceKey;
  final DashboardRepository repository;
  final revision = ValueNotifier(0);
  Map<String, String> _dashboards = {};
  Future<void> _writes = Future.value();

  Future<void> initialize() async {
    _dashboards = await repository.load();
  }

  GridLayout? forDevice(RemoteDevice device) =>
      _decode(_dashboards[_key(device)] ?? _dashboards[device.id]);

  String _key(RemoteDevice device) => deviceKey?.call(device) ?? device.id;

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
    final key = _key(device);
    await _enqueue(() => _persist({..._dashboards, key: layout.encode()}));
  }

  Future<void> removeForDevice(Iterable<String> ids) {
    final keys = ids.toSet();
    return _enqueue(() async {
      final next = {..._dashboards}
        ..removeWhere((key, _) => keys.contains(key));
      if (next.length == _dashboards.length) {
        return;
      }
      await _persist(next);
    });
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _writes.then((_) => operation());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _persist(Map<String, String> next) async {
    await repository.save(next);
    _dashboards = next;
    revision.value++;
  }

  Future<void> dispose() async {
    await _writes;
    revision.dispose();
  }
}
