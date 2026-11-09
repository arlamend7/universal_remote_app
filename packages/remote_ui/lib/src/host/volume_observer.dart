import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:remote_core/remote_core.dart';

final class VolumeObserver {
  final value = ValueNotifier<VolumeState?>(null);
  StreamSubscription<VolumeState>? _subscription;
  TVRemoteBase? _owner;
  int _generation = 0;
  Future<void> sync(RemoteBase controller) async {
    if (controller.supports(RemoteCapability.volumeFeedback)) {
      if (!identical(_owner, controller)) {
        await observe(controller);
      }
      return;
    }
    if (identical(_owner, controller)) {
      value.value = null;
      await detach();
    }
  }

  Future<void> observe(RemoteBase controller) async {
    final detaching = detach();
    final generation = _generation;
    await detaching;
    if (generation != _generation) {
      return;
    }
    if (controller is! TVRemoteBase ||
        !controller.supports(RemoteCapability.volumeFeedback)) {
      return;
    }
    _owner = controller;
    await refresh();
    if (generation != _generation) {
      return;
    }
    _subscription = controller.watchVolume().listen(
      _received,
      onError: _ignored,
    );
  }

  Future<void> refresh() async {
    final generation = _generation;
    final owner = _owner;
    if (owner == null) {
      return;
    }
    try {
      final reading = await owner.readVolume();
      if (generation != _generation) {
        return;
      }
      _received(reading);
    } catch (_) {
      if (generation == _generation) {
        value.value = null;
      }
    }
  }

  void _received(VolumeState reading) {
    if (value.value?.volume == reading.volume &&
        value.value?.muted == reading.muted) {
      return;
    }
    value.value = reading;
  }

  void _ignored(Object _) {}
  Future<void> detach() async {
    ++_generation;
    _owner = null;
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() async {
    await detach();
    value.dispose();
  }
}
