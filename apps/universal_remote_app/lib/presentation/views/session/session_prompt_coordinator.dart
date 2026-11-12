import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../../domains/session/services/active_session.dart';
import '../../../routes/open_remote_editor.dart';
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
  int _navigationActions = 0;
  int _lastInterstitialAction = -1;
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

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is TransitionRoute<dynamic> &&
        route.settings.name == remoteEditorRouteName &&
        previousRoute?.isFirst == true) {
      unawaited(_afterEditor(route, previousRoute!));
    }
  }

  Future<void> _afterEditor(
    TransitionRoute<dynamic> editor,
    Route<dynamic> returnRoute,
  ) async {
    final action = ++_navigationActions;
    await editor.completed;
    await _tryInterstitial(action, () => identical(_top, returnRoute));
  }

  void onTabChanged({bool Function()? stillAtBreak}) {
    final action = ++_navigationActions;
    if (stillAtBreak == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_tryInterstitial(action, stillAtBreak));
    });
  }

  Future<void> _tryInterstitial(
    int action,
    bool Function() stillAtBreak,
  ) async {
    if (action - _lastInterstitialAction < 2) {
      return;
    }
    final shown = await session.showInterstitial(
      canPresent: () =>
          action == _navigationActions && _canShowInterstitial(stillAtBreak),
    );
    if (shown) {
      _lastInterstitialAction = action;
    }
  }

  bool _canShowInterstitial(bool Function() stillAtBreak) =>
      !_disposed &&
      !_open &&
      !_blocked &&
      _top?.isFirst == true &&
      _top?.isCurrent == true &&
      stillAtBreak();

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
    if (!session.warningDue) {
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
