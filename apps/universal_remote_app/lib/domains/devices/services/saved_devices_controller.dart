import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../repositories/device_profile_repository.dart';

class SavedDevicesController {
  SavedDevicesController(this.repository, this.credentials);
  final DeviceProfileRepository repository;
  final CredentialStore credentials;
  final devices = ValueNotifier<List<RemoteDevice>>([]);
  Future<void>? _writes;
  bool _closing = false;
  Future<void> _write(Future<void> Function() action) {
    if (_closing) {
      return Future.error(StateError('Device profiles are closed.'));
    }
    final previous = _writes;
    final result = previous == null
        ? Future<void>.sync(action)
        : previous.then((_) => action());
    final settled = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _writes = settled;
    unawaited(
      settled.then((_) {
        if (identical(_writes, settled)) {
          _writes = null;
        }
      }),
    );
    return result;
  }

  RemoteDevice? _latest(String id) =>
      devices.value.where((item) => item.id == id).firstOrNull;
  Future<void> updateExisting(
    String id,
    RemoteDevice? Function(RemoteDevice) update,
  ) => _write(() async {
    final current = _latest(id);
    if (current == null) {
      return;
    }
    final changed = update(current);
    if (changed != null) {
      await _save(changed);
    }
  });
  Future<void> initialize() async {
    devices.value = await repository.load();
  }

  Future<void> save(RemoteDevice device) => _write(() => _save(device));
  Future<void> _save(RemoteDevice device) async {
    final exists = devices.value.any((item) => item.id == device.id);
    final next = exists
        ? devices.value
              .map((item) => item.id == device.id ? device : item)
              .toList()
        : [...devices.value, device];
    await repository.save(next);
    devices.value = next;
  }

  Future<void> rename(RemoteDevice device, String name) async {
    if (name.trim().isEmpty) {
      throw const RemoteException('name', 'Enter a device name.');
    }
    await _write(
      () => _save(copyDevice(_latest(device.id) ?? device, name: name.trim())),
    );
  }

  Future<void> forget(RemoteDevice device) => _write(() async {
    // Delete secrets first. A failed metadata write never retains authorization.
    await credentials.delete(device.id);
    final next = devices.value.where((e) => e.id != device.id).toList();
    await repository.save(next);
    devices.value = next;
  });

  Future<void> dispose() async {
    _closing = true;
    await _writes;
    devices.dispose();
  }
}
