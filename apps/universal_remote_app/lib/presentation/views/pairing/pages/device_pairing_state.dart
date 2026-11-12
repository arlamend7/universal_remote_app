import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../shared/widgets/connection_issue_page.dart';
import '../../remote/viewmodels/remote_viewmodel.dart';
import '../widgets/pairing_progress_card.dart';
import '../widgets/pairing_step_page.dart';
import 'device_pairing_page.dart';

class DevicePairingState extends State<DevicePairingPage> {
  late final _model = RemoteViewModel(widget.dependencies);
  late RemoteDevice _target = widget.device;
  Timer? _success;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_connect());
      }
    });
  }

  Future<void> _connect() async {
    await _model.connection.connect(_target);
    if (mounted && _model.state == DeviceConnectionState.connected) {
      _showSuccess();
    }
  }

  void _showSuccess() {
    if (_success != null) {
      return;
    }
    setState(
      () => _success = Timer(const Duration(milliseconds: 420), () {
        _success = null;
        if (!mounted ||
            ModalRoute.of(context)?.isCurrent != true ||
            _model.state != DeviceConnectionState.connected) {
          return;
        }
        Navigator.pop(context, _model.device ?? _target);
      }),
    );
  }

  void _close() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: _model.changes, builder: _content);

  Widget _content(BuildContext context, Widget? child) {
    if (_success != null && _model.state == DeviceConnectionState.connected) {
      return PairingStepPage(
        device: _model.device ?? _target,
        onBack: _close,
        connected: true,
        body: ListTile(
          leading: Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('TV connected!'),
        ),
      );
    }
    if (_model.device?.id == _target.id &&
        _model.state == DeviceConnectionState.disconnected &&
        _model.error != null) {
      return _failure();
    }
    return PairingProgressCard(
      model: _model,
      onCancel: _close,
      setupDevice: _target,
    );
  }

  Widget _failure() => PairingStepPage(
    device: _target,
    onBack: _close,
    body: ConnectionIssuePage(
      title: 'Could not connect',
      description: _model.error!,
      icon: Icons.link_off,
      actions: [
        if (_model.canReviewCertificate)
          OutlinedButton(
            onPressed: _reviewCertificate,
            child: Text('Review certificate'),
          ),
      ],
    ),
    secondary: OutlinedButton(onPressed: _close, child: const Text('Cancel')),
    primary: FilledButton(onPressed: _connect, child: const Text('Try again')),
  );

  Future<void> _reviewCertificate() async {
    await _model.reviewCertificate(context);
    if (!mounted) {
      return;
    }
    _target = _model.device ?? _target;
    if (_model.state == DeviceConnectionState.connected) {
      _showSuccess();
    }
  }

  @override
  void dispose() {
    _success?.cancel();
    super.dispose();
  }
}
