import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../../shared/localization/journey_text.dart';
import '../../../shared/widgets/connection_issue_page.dart';
import '../../remote/viewmodels/remote_viewmodel.dart';
import '../widgets/pairing_progress_card.dart';
import 'device_pairing_sheet.dart';

class DevicePairingState extends State<DevicePairingSheet> {
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

  String _text(String en, String pt) => journeyText(context, en, pt);

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
        if (!mounted || _model.state != DeviceConnectionState.connected) {
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
      return AppSheet(
        title: _text('TV connected!', 'TV conectada!'),
        subtitle: _model.device?.name ?? _target.name,
        onClose: _close,
        child: Icon(
          Icons.check_circle_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (_model.state == DeviceConnectionState.disconnected &&
        _model.error != null) {
      return _failure();
    }
    return PairingProgressCard(model: _model, onCancel: _close);
  }

  Widget _failure() => AppSheet(
    title: _target.name,
    onClose: _close,
    child: ConnectionIssuePage(
      title: _text('Could not connect', 'Não foi possível conectar'),
      description: _model.error!,
      icon: Icons.link_off,
      actions: [
        if (_model.canReviewCertificate)
          OutlinedButton(
            onPressed: _reviewCertificate,
            child: Text(_text('Review certificate', 'Verificar certificado')),
          ),
        TextButton(onPressed: _close, child: Text(_text('Back', 'Voltar'))),
        FilledButton(
          onPressed: _connect,
          child: Text(_text('Try again', 'Tentar novamente')),
        ),
      ],
    ),
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
