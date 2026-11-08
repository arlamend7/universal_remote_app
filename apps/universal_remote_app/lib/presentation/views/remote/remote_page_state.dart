import 'package:remote_core/remote_core.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../pairing/widgets/pairing_progress_card.dart';
import 'remote_page.dart';
import 'viewmodels/remote_viewmodel.dart';
import 'viewports/remote_viewport.dart';
import 'widgets/remote_empty_state.dart';

class RemotePageState extends State<RemotePage> {
  late final model = RemoteViewModel(widget.dependencies);
  bool _pairingOpen = false;
  bool _offlineOpen = false;
  int? _offlineAttempt;
  BuildContext? _pairingContext;
  @override
  void initState() {
    super.initState();
    widget.dependencies.connection.state.addListener(_stateChanged);
    _stateChanged();
  }

  @override
  void didUpdateWidget(covariant RemotePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _stateChanged();
    }
  }

  void _stateChanged() {
    if (!widget.active) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePairing());
  }

  void _updatePairing() {
    if (!mounted || !widget.active) {
      return;
    }
    if (!model.isPairing) {
      _closePairing();
      WidgetsBinding.instance.addPostFrameCallback((_) => _offerOffline());
      return;
    }
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    if (_pairingOpen) {
      return;
    }
    _pairingOpen = true;
    unawaited(_showPairing());
  }

  Future<void> _showPairing() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: _pairing,
    );
    _pairingOpen = false;
    _pairingContext = null;
    _offerOffline();
  }

  Widget _pairing(BuildContext context) {
    _pairingContext = context;
    return ListenableBuilder(
      listenable: model.changes,
      builder: (_, child) => PairingProgressCard(model: model),
    );
  }

  void _closePairing() {
    final context = _pairingContext;
    if (context != null &&
        context.mounted &&
        ModalRoute.of(context)?.isCurrent == true) {
      _pairingContext = null;
      Navigator.pop(context);
    }
  }

  void _offerOffline() {
    if (!mounted ||
        !widget.active ||
        !model.offline ||
        model.device == null ||
        (model.canWake && model.error == null) ||
        model.connection.disconnectReason.value == DisconnectReason.suspended ||
        (model.error == null &&
            model.connection.disconnectReason.value == DisconnectReason.user) ||
        _offlineOpen ||
        _pairingOpen ||
        model.connection.attempt == 0 ||
        _offlineAttempt == model.connection.attempt ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _offlineAttempt = model.connection.attempt;
    _offlineOpen = true;
    unawaited(_showOffline());
  }

  Future<void> _showOffline() async {
    await model.showStatus(context);
    _offlineOpen = false;
  }

  @override
  void dispose() {
    widget.dependencies.connection.state.removeListener(_stateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: model.shellChanges, builder: _content);
  Widget _content(BuildContext context, Widget? child) {
    if (model.device == null) {
      return RemoteEmptyState(onChooseDevice: widget.onChooseDevice);
    }
    return RemoteViewport(model: model);
  }
}
