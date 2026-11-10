import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:remote_core/remote_core.dart';

/// Owns optional current-content feedback and releases it with the TV session.
final class CurrentContentObserver {
  final value = ValueNotifier<CurrentContent?>(null);
  // Cancelled through the captured subscription in detach, before session disposal.
  // ignore: cancel_subscriptions
  StreamSubscription<CurrentContent>? _subscription;
  TVRemoteBase? _owner;
  Timer? _timer;
  int _generation = 0;
  bool _reading = false;

  Future<void> observe(RemoteBase controller) async {
    final detaching = detach();
    final generation = _generation;
    await detaching;
    if (generation != _generation) {
      return;
    }
    if (controller is! TVRemoteBase ||
        !controller.supports(RemoteCapability.currentContent)) {
      return;
    }
    _owner = controller;
    _subscription = controller.watchCurrentContent().listen(
      (content) => _received(content, generation),
      onError: _ignored,
    );
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(refresh()),
    );
    await refresh();
  }

  Future<void> refresh() async {
    final owner = _owner;
    if (owner == null || _reading) {
      return;
    }
    final generation = _generation;
    _reading = true;
    try {
      _received(await owner.currentContent(), generation);
    } catch (_) {
      _clearValue(generation);
    } finally {
      if (generation == _generation) {
        _reading = false;
      }
    }
  }

  void _received(CurrentContent content, int generation) {
    if (generation != _generation) {
      return;
    }
    final old = value.value;
    if (old?.appId == content.appId &&
        old?.appName == content.appName &&
        old?.channelName == content.channelName &&
        old?.channelNumber == content.channelNumber &&
        old?.liveTv == content.liveTv &&
        old?.programTitle == content.programTitle &&
        old?.position == content.position &&
        old?.duration == content.duration) {
      return;
    }
    value.value = content;
  }

  void _clearValue(int generation) {
    if (generation == _generation) {
      value.value = null;
    }
  }

  void _ignored(Object _) {}
  Future<void> detach() async {
    ++_generation;
    _timer?.cancel();
    _timer = null;
    _owner = null;
    _reading = false;
    value.value = null;
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  Future<void> dispose() async {
    await detach();
    value.dispose();
  }
}
