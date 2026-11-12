import 'dart:async';

import '../../remote_base.dart';
import '../enums/device_connection_state.dart';

/// Owns one driver and its state subscription; disposal can be awaited repeatedly.
final class DeviceSession {
  DeviceSession(this.controller);
  final RemoteBase controller;
  StreamSubscription<DeviceConnectionState>? _states;
  StreamSubscription<void>? _capabilities;
  Future<void>? _disposeFuture;
  void observe(
    void Function(DeviceConnectionState) onState, {
    void Function()? onCapabilities,
  }) {
    _states = controller.connectionStates.listen(onState);
    if (onCapabilities != null) {
      _capabilities = controller.capabilityChanges.listen(
        (_) => onCapabilities(),
      );
    }
  }

  Future<void> dispose() => _disposeFuture ??= _dispose();
  Future<void> _dispose() async {
    await _capabilities?.cancel();
    await _states?.cancel();
    _states = null;
    await controller.dispose();
  }
}
