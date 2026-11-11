import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:remote_ui/remote_ui.dart';

import 'pairing_code_card.dart';

import '../../remote/viewmodels/remote_viewmodel.dart';

class PairingProgressCard extends StatelessWidget {
  const PairingProgressCard({super.key, required this.model});
  final RemoteViewModel model;
  String get _title => switch (model.state) {
    DeviceConnectionState.pairing => 'Approve the connection on your TV',
    DeviceConnectionState.reconnecting => 'Waiting for your TV to start…',
    _ => 'Connecting securely…',
  };
  @override
  Widget build(BuildContext context) {
    final controller = model.connection.controller;
    if (model.state == DeviceConnectionState.pairing &&
        controller is PairingCodeReceiver) {
      return PairingCodeCard(
        receiver: controller as PairingCodeReceiver,
        onCancel: model.disconnect,
        deviceName: model.device?.name ?? 'your TV',
      );
    }
    final installing =
        controller is ManagedTvController && controller.installing;
    return AppSheet(
      title: installing ? 'Installing TV driver…' : _title,
      onClose: model.disconnect,
      child: _body(installing),
      footer: AppSheetActions(
        primary: OutlinedButton(
          onPressed: model.disconnect,
          child: const Text('Cancel connection'),
        ),
      ),
    );
  }

  Widget _body(bool installing) => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: [
      const SizedBox.square(
        dimension: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
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
