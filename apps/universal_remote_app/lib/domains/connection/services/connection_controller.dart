import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../devices/services/saved_devices_controller.dart';
import '../../diagnostics/services/diagnostic_logger.dart';
import '../../diagnostics/models/enums/app_log_level.dart';

/// Coordinates selection and sessions, without storage details or protocol names.
class ConnectionController implements RemotePanelSession {
  ConnectionController(
    this.registry,
    this.saved,
    this.logger, {
    this.wakeLearner,
    this.removeDashboards,
    this.autoReconnect,
    this.wakeRetryDelay = const Duration(seconds: 2),
  });
  final DeviceWakeLearner? wakeLearner;
  final Future<void> Function(Iterable<String>)? removeDashboards;
  final bool Function()? autoReconnect;
  final Duration wakeRetryDelay;

  final ProviderRegistry registry;
  final SavedDevicesController saved;
  final DiagnosticLogger logger;
  final ValueNotifier<RemoteDevice?> selected = ValueNotifier<RemoteDevice?>(
    null,
  );
  final ValueNotifier<DeviceConnectionState> state = ValueNotifier(
    DeviceConnectionState.disconnected,
  );
  final error = ValueNotifier<String?>(null);
  final errorCode = ValueNotifier<String?>(null);
  final ValueNotifier<int> revision = ValueNotifier(0);
  final disconnectReason = ValueNotifier(DisconnectReason.user);
  int get attempt => _generation;
  final _volume = VolumeObserver();
  final _content = CurrentContentObserver();
  late final _commands = RemoteCommandController(
    onFailure: (code) =>
        logger.record(AppLogLevel.warning, 'command_failed', errorCode: code),
    volume: _volume,
    error: error,
    generation: () => _generation,
    onUpdated: _updated,
  );
  ValueNotifier<CurrentContent?> get currentContent => _content.value;
  Future<void> refreshContent() => _content.refresh();
  ValueNotifier<VolumeState?> get volume => _volume.value;
  ValueNotifier<bool> get commandBusy => _commands.busy;
  RemoteBase? get controller => _session?.controller;
  DeviceSession? _session;
  Future<void> _cleanup = Future.value();
  Future<void>? _disposeFuture;
  int _generation = 0;
  bool _disposed = false;
  bool _resumeConnection = false;
  bool _isCurrent(int generation) => !_disposed && generation == _generation;
  Future<void> connect(RemoteDevice device) {
    final activeId = selected.value?.id;
    final logical = saved.logicalDevice(device.id);
    if (state.value == DeviceConnectionState.connected &&
        activeId != device.id &&
        logical?.profiles.any((profile) => profile.id == activeId) == true) {
      return Future.value();
    }
    return _startConnection(device);
  }

  Future<void> turnOn(RemoteDevice device) {
    if (_disposed ||
        !registry.canWake(device) ||
        (selected.value?.id == device.id &&
            state.value != DeviceConnectionState.disconnected) ||
        commandBusy.value) {
      return Future.value();
    }
    return _startConnection(device, waking: true);
  }

  Future<void> _startConnection(
    RemoteDevice device, {
    bool waking = false,
    bool allowFallback = true,
  }) async {
    if (_disposed ||
        (_sameTarget(device) &&
            state.value != DeviceConnectionState.disconnected)) {
      return;
    }
    final generation = ++_generation;
    final cleanup = _clear();
    selected.value = device;
    disconnectReason.value = DisconnectReason.user;
    error.value = null;
    errorCode.value = null;
    volume.value = null;
    state.value = waking
        ? DeviceConnectionState.reconnecting
        : DeviceConnectionState.connecting;
    await cleanup;
    if (!_isCurrent(generation)) {
      return;
    }
    try {
      await DeviceConnectionWorkflow(retryDelay: wakeRetryDelay).run(
        wake: waking ? () => registry.wake(device) : null,
        connect: () => _connectAttempt(device, generation, waking: waking),
        isCurrent: () => _isCurrent(generation),
        canRetry: (error) =>
            state.value == DeviceConnectionState.reconnecting &&
            registry.canRetryAfterWake(device, error),
        reset: _clear,
      );
    } catch (exception) {
      if (allowFallback &&
          !waking &&
          await _tryFallback(device, exception, generation)) {
        return;
      }
      await _connectionFailed(_session, exception, generation);
    }
  }

  Future<bool> _tryFallback(
    RemoteDevice failed,
    Object error,
    int generation,
  ) async {
    if (!_isCurrent(generation) || !_isFallbackFailure(error)) {
      return false;
    }
    final logical = saved.logicalDevice(failed.id);
    if (logical == null) {
      return false;
    }
    for (final profile in logical.profiles) {
      if (await _canFallback(profile, failed, generation)) {
        await _startConnection(
          copyDevice(profile.device, name: logical.name),
          allowFallback: false,
        );
        return true;
      }
    }
    return false;
  }

  bool _isFallbackFailure(Object error) => switch (error) {
    RemoteException(:final code) => const {
      'network',
      'connectionRefused',
      'timeout',
    }.contains(code),
    SocketException(:final osError) => const {
      50,
      51,
      60,
      61,
      64,
      65,
      100,
      101,
      110,
      111,
      113,
    }.contains(osError?.errorCode),
    _ => false,
  };

  Future<bool> _canFallback(
    ConnectionProfile profile,
    RemoteDevice failed,
    int generation,
  ) async {
    if (!_isCurrent(generation) ||
        !profile.confirmed ||
        profile.providerId == failed.providerId ||
        !registry.isRegistered(profile.providerId)) {
      return false;
    }
    try {
      final credential = await saved.credentials.read(profile.id);
      return _isCurrent(generation) &&
          credential != null &&
          credential.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _connectAttempt(
    RemoteDevice device,
    int generation, {
    required bool waking,
  }) {
    logger.record(AppLogLevel.info, 'connect');
    final session = _createSession(device, generation, waking: waking);
    return _connectSession(session, device, generation);
  }

  bool _sameTarget(RemoteDevice device) {
    final previous = selected.value;
    return previous != null && registry.sameConnection(previous, device);
  }

  DeviceSession _createSession(
    RemoteDevice device,
    int generation, {
    required bool waking,
  }) {
    final session = DeviceSession(registry.createController(device));
    _session = session;
    void onState(DeviceConnectionState value) {
      if (waking && _isWakeStartupState(value)) {
        return;
      }
      _stateChanged(session, value, generation);
    }

    session.observe(
      onState,
      onCapabilities: () {
        if (!_isCurrent(generation) || !identical(_session, session)) {
          return;
        }
        _updated();
        unawaited(_volume.sync(session.controller));
      },
    );
    return session;
  }

  bool _isWakeStartupState(DeviceConnectionState next) =>
      state.value == DeviceConnectionState.reconnecting &&
      (next == DeviceConnectionState.connecting ||
          next == DeviceConnectionState.disconnected);

  Future<void> _connectSession(
    DeviceSession session,
    RemoteDevice device,
    int generation,
  ) async {
    await session.controller.connect();
    if (!_isCurrent(generation)) {
      return;
    }
    final latest = saved.byId(device.id);
    final identity = session.controller.verifiedPeerIdentity;
    final discoveryIdentity = session.controller.reportedDiscoveryIdentity;
    await saved.save(
      copyDevice(
        device,
        capabilities: resolvedCapabilities(session.controller),
        category: session.controller.device.category,
        model: session.controller.device.model,
        metadata: {
          ...device.metadata,
          ...?latest?.metadata,
          if (session.controller.device.metadata['softwareVersion']
              case final version?)
            'softwareVersion': version,
          if (identity != null) 'verifiedPeerIdentity': identity,
          if (discoveryIdentity != null) 'discoveryIdentity': discoveryIdentity,
          'lastConnectedAt': DateTime.now().toUtc().toIso8601String(),
        },
      ),
    );
    _updated();
    unawaited(
      wakeLearner?.learn(
        session.controller,
        device,
        isCurrent: () =>
            _isCurrent(generation) &&
            identical(_session, session) &&
            state.value == DeviceConnectionState.connected,
      ),
    );
  }

  void _stateChanged(
    DeviceSession session,
    DeviceConnectionState next,
    int generation,
  ) {
    if (!_isCurrent(generation)) {
      return;
    }
    final previous = state.value;
    if (next == previous) {
      return;
    }
    if (next == DeviceConnectionState.disconnected &&
        previous == DeviceConnectionState.connected) {
      disconnectReason.value = DisconnectReason.connectionLost;
    }
    state.value = next;
    _updated();
    if (next != DeviceConnectionState.connected) {
      unawaited(_content.detach());
      return;
    }
    unawaited(_volume.observe(session.controller));
    unawaited(_content.observe(session.controller));
  }

  Future<void> _connectionFailed(
    DeviceSession? session,
    Object exception,
    int generation,
  ) async {
    if (!_isCurrent(generation)) {
      return;
    }
    await session?.controller.disconnect();
    if (!_isCurrent(generation)) {
      return;
    }
    errorCode.value = exception is RemoteException ? exception.code : 'unknown';
    error.value = exception is RemoteException
        ? exception.message
        : 'The operation failed. Please try again.';
    state.value = DeviceConnectionState.disconnected;
    logger.record(
      AppLogLevel.warning,
      'connect_failed',
      errorCode: exception is RemoteException ? exception.code : 'unknown',
    );
  }

  @override
  bool supports(RemoteCapability capability) =>
      state.value == DeviceConnectionState.connected &&
      (controller?.supports(capability) ?? false);

  @override
  TVRemoteBase? tvWith(RemoteCapability capability) {
    final current = controller;
    if (current is! TVRemoteBase || !supports(capability)) {
      return null;
    }
    return current;
  }

  Future<void> execute(
    Future<void> Function() command, {
    bool refreshVolume = false,
  }) => _commands.execute(command, refreshVolume: refreshVolume);
  @override
  void refreshControls() => _updated();

  @override
  void reportError(String message) => error.value = message;

  void _updated() {
    revision.value++;
  }

  Future<void> _clear() {
    final session = _session;
    _session = null;
    _cleanup = _cleanup.then((_) => _releaseSession(session));
    return _cleanup;
  }

  Future<void> _releaseSession(DeviceSession? session) async {
    await _volume.detach();
    await _content.detach();
    await session?.dispose();
  }

  Future<void> disconnect({
    DisconnectReason reason = DisconnectReason.user,
  }) async {
    final generation = ++_generation;
    _resumeConnection = false;
    await _clear();
    if (!_isCurrent(generation)) {
      return;
    }
    error.value = null;
    errorCode.value = null;
    disconnectReason.value = reason;
    state.value = DeviceConnectionState.disconnected;
    _updated();
  }

  Future<void> powerOff() => execute(() async {
    final power = controller;
    final generation = _generation;
    if (power == null || !supports(RemoteCapability.power)) {
      throw const RemoteException(
        'powerUnavailable',
        'Power off is unavailable for this connection.',
      );
    }
    await power.powerOff();
    if (_isCurrent(generation)) {
      await disconnect(reason: DisconnectReason.poweredOff);
    }
  });

  Future<void> rePair() async {
    final device = selected.value;
    if (device == null) {
      return;
    }
    await disconnect();
    await saved.credentials.delete(device.id);
    await connect(device);
  }

  Future<void> forget(RemoteDevice device) async {
    final logical = saved.logicalDevice(device.id);
    await _deselect(device);
    await removeDashboards?.call({
      device.id,
      if (logical != null) logical.id,
      ...?logical?.profiles.map((profile) => profile.id),
    });
    await saved.forget(device);
  }

  Future<void> _deselect(RemoteDevice device) async {
    final selectedId = selected.value?.id;
    if (selectedId != device.id &&
        saved
                .logicalDevice(device.id)
                ?.profiles
                .any((profile) => profile.id == selectedId) !=
            true) {
      return;
    }
    final disconnecting = disconnect();
    final generation = _generation;
    await disconnecting;
    if (_isCurrent(generation)) {
      selected.value = null;
    }
  }

  Future<void> lifecycle(AppLifecycleState lifecycle) async {
    if (lifecycle == AppLifecycleState.resumed) {
      await _resume();
      return;
    }
    if (lifecycle != AppLifecycleState.paused &&
        lifecycle != AppLifecycleState.hidden) {
      return;
    }
    await _suspend();
  }

  Future<void> _suspend() async {
    _resumeConnection =
        _resumeConnection || state.value == DeviceConnectionState.connected;
    ++_generation;
    await _clear();
    if (_disposed) {
      return;
    }
    disconnectReason.value = DisconnectReason.suspended;
    state.value = DeviceConnectionState.disconnected;
  }

  Future<void> _resume() async {
    if (!_resumeConnection) {
      return;
    }
    _resumeConnection = false;
    if (autoReconnect?.call() == false) {
      return;
    }
    final device = selected.value;
    if (device == null) {
      return;
    }
    await connect(device);
  }

  Future<void> dispose() => _disposeFuture ??= _dispose();
  Future<void> _dispose() async {
    _disposed = true;
    ++_generation;
    _commands.dispose();
    await _clear();
    await _volume.dispose();
    await _content.dispose();
    selected.dispose();
    state.dispose();
    error.dispose();
    errorCode.dispose();
    revision.dispose();
    disconnectReason.dispose();
  }
}
