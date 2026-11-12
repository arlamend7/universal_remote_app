import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/integrations.dart';
import 'package:remote_ui/remote_ui.dart';

import 'pairing_code_card.dart';

import '../../remote/viewmodels/remote_viewmodel.dart';

class PairingProgressCard extends StatelessWidget {
  const PairingProgressCard({super.key, required this.model, this.onCancel});
  final RemoteViewModel model;
  final VoidCallback? onCancel;
  VoidCallback get _cancel => onCancel ?? model.disconnect;
  String get _title => switch (model.state) {
    DeviceConnectionState.pairing => 'Approve the connection on your TV',
    DeviceConnectionState.reconnecting => 'Waiting for your TV to start…',
    _ => 'Connecting securely…',
  };
  @override
  Widget build(BuildContext context) {
    final controller = model.connection.controller;
    if (model.state == DeviceConnectionState.pairing &&
        controller is PairingCodeReceiver &&
        (controller as PairingCodeReceiver).awaitingPairingCode) {
      return PairingCodeCard(
        receiver: controller as PairingCodeReceiver,
        onCancel: _cancel,
        deviceName: model.device?.name ?? 'your TV',
      );
    }
    final installing =
        controller is GenericTvController && controller.installing;
    return AppSheet(
      title: installing ? 'Installing TV driver…' : _title,
      subtitle: model.device?.name,
      onClose: _cancel,
      child: _body(
        installing,
        controller is GenericTvController ? controller.installProgress : null,
      ),
      footer: AppSheetActions(
        primary: OutlinedButton(
          onPressed: _cancel,
          child: Text('Cancel connection'),
        ),
      ),
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
              : 'Keep the TV on and accept its connection request.',
          textAlign: TextAlign.center,
        ),
    ],
  );
}
