import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:remote_core/remote_core.dart';

import 'remote_panel_session.dart';

/// Foreground local timer only. Never acts on a different or reconnected session.
final class DeviceSleepController {
  DeviceSleepController(this.connection) {
    connection.selected.addListener(_cancel);
    connection.state.addListener(_stateChanged);
  }
  final RemotePanelSession connection;
  final deadline = ValueNotifier<DateTime?>(null);
  Timer? _timer;
  RemoteBase? _owner;
  void schedule(RemoteDevice device, Duration duration) {
    _cancel();
    if (connection.selected.value?.id != device.id ||
        connection.state.value != DeviceConnectionState.connected ||
        duration <= Duration.zero) {
      return;
    }
    _owner = connection.controller;
    deadline.value = DateTime.now().add(duration);
    _timer = Timer(duration, () => unawaited(_fire()));
  }

  Future<void> _fire() async {
    final owner = _owner;
    _cancel();
    if (!identical(connection.controller, owner) ||
        connection.state.value != DeviceConnectionState.connected) {
      return;
    }
    await connection.powerOff();
  }

  void _stateChanged() {
    if (connection.state.value != DeviceConnectionState.connected) {
      _cancel();
    }
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    _owner = null;
    deadline.value = null;
  }

  void cancel() => _cancel();
  void dispose() {
    connection.selected.removeListener(_cancel);
    connection.state.removeListener(_stateChanged);
    _cancel();
    deadline.dispose();
  }
}
