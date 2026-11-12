import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/integrations.dart';
import 'package:remote_ui/remote_ui.dart';

import 'pairing_code_card.dart';
import 'pairing_step_page.dart';

import '../../remote/viewmodels/remote_viewmodel.dart';

class PairingProgressCard extends StatelessWidget {
  const PairingProgressCard({
    super.key,
    required this.model,
    this.onCancel,
    this.setupDevice,
  });
  final RemoteViewModel model;
  final VoidCallback? onCancel;
  final RemoteDevice? setupDevice;
  VoidCallback get _cancel => onCancel ?? model.disconnect;
  String get _title => switch (model.state) {
    DeviceConnectionState.pairing => 'Approve the connection on your TV',
    DeviceConnectionState.reconnecting => 'Waiting for your TV to start…',
    _ => 'Connecting securely…',
  };
  @override
  Widget build(BuildContext context) {
    final current = setupDevice == null || model.device?.id == setupDevice?.id;
    final controller = current ? model.connection.controller : null;
    if (model.state == DeviceConnectionState.pairing &&
        controller is PairingCodeReceiver &&
        (controller as PairingCodeReceiver).awaitingPairingCode) {
      return PairingCodeCard(
        receiver: controller as PairingCodeReceiver,
        onCancel: _cancel,
        deviceName: model.device?.name ?? setupDevice?.name ?? 'your TV',
        setupDevice: setupDevice,
      );
    }
    final installing =
        controller is GenericTvController && controller.installing;
    final progress = controller is GenericTvController
        ? controller.installProgress
        : null;
    final title = installing ? 'Installing TV driver…' : _title;
    final message = current ? title : 'Connecting securely…';
    final cancel = OutlinedButton(
      onPressed: _cancel,
      child: const Text('Cancel connection'),
    );
    final device = setupDevice;
    if (device != null) {
      return PairingStepPage(
        device: device,
        onBack: _cancel,
        body: Column(
          spacing: 16,
          children: [
            Text(message, style: Theme.of(context).textTheme.titleLarge),
            _body(installing, progress),
          ],
        ),
        primary: cancel,
      );
    }
    return AppSheet(
      title: title,
      subtitle: model.device?.name,
      onClose: _cancel,
      child: _body(installing, progress),
      footer: AppSheetActions(primary: cancel),
    );
  }

  Widget _body(bool installing, double? progress) => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: [
      if (model.state == DeviceConnectionState.pairing)
        const Icon(Icons.tv_outlined, size: 32),
      SizedBox.square(
        dimension: 28,
        child: CircularProgressIndicator(strokeWidth: 2, value: progress),
      ),
      if (!installing)
        Text(
          model.state == DeviceConnectionState.reconnecting
              ? 'The remote will connect automatically when the TV is ready.'
              : 'Keep the TV on and accept any connection request it displays.',
          textAlign: TextAlign.center,
        ),
    ],
  );
}
