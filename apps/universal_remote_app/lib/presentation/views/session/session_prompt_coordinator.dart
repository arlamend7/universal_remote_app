import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../../domains/session/services/active_session.dart';
import 'session_time_sheet.dart';

final class SessionPromptCoordinator extends NavigatorObserver {
  SessionPromptCoordinator(this.session, this.connection, this.discovering) {
    session.addListener(_queueCheck);
    connection.addListener(_queueCheck);
    discovering.addListener(_queueCheck);
  }

  final ActiveSession session;
  final ValueNotifier<DeviceConnectionState> connection;
  final ValueNotifier<bool> discovering;
  final shellVisible = ValueNotifier(false);
  Route<dynamic>? _top;
  bool _queued = false;
  bool _open = false;
  bool _disposed = false;

  bool get _blocked =>
      connection.value == DeviceConnectionState.pairing ||
      connection.value == DeviceConnectionState.connecting ||
      discovering.value ||
      _top is PopupRoute<dynamic>;

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    _top = topRoute;
    _queueCheck();
  }

  void _queueCheck() {
    if (_queued || _disposed) {
      return;
    }
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback(_check);
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _check(Duration _) {
    _queued = false;
    if (_disposed) {
      return;
    }
    shellVisible.value = _top?.isFirst == true;
    if (!session.warningDue && !session.expirationDue) {
      return;
    }
    if (_open) {
      session.acknowledgePrompt();
      return;
    }
    if (!_blocked) {
      unawaited(open());
    }
  }

  Future<void> open() async {
    final context = navigator?.overlay?.context;
    if (_disposed || _open || _blocked || context == null) {
      return;
    }
    _open = true;
    session.acknowledgePrompt();
    try {
      await showAppModal<void>(
        context,
        builder: (_) => SessionTimeSheet(session: session),
      );
    } finally {
      _open = false;
      _queueCheck();
    }
  }

  void dispose() {
    _disposed = true;
    session.removeListener(_queueCheck);
    connection.removeListener(_queueCheck);
    discovering.removeListener(_queueCheck);
    shellVisible.dispose();
  }
}
