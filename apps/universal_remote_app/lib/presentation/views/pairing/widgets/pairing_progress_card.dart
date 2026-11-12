import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/integrations.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../../shared/localization/journey_text.dart';
import 'pairing_code_card.dart';

import '../../remote/viewmodels/remote_viewmodel.dart';

class PairingProgressCard extends StatelessWidget {
  const PairingProgressCard({super.key, required this.model, this.onCancel});
  final RemoteViewModel model;
  final VoidCallback? onCancel;
  VoidCallback get _cancel => onCancel ?? model.disconnect;
  String _title(BuildContext context) => switch (model.state) {
    DeviceConnectionState.pairing => journeyText(
      context,
      'Approve the connection on your TV',
      'Autorize a conexão na sua TV',
    ),
    DeviceConnectionState.reconnecting => journeyText(
      context,
      'Waiting for your TV to start…',
      'Aguardando a TV ligar…',
    ),
    _ => journeyText(
      context,
      'Connecting securely…',
      'Conectando com segurança…',
    ),
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
      title: installing
          ? journeyText(
              context,
              'Installing TV driver…',
              'Instalando o driver da TV…',
            )
          : _title(context),
      subtitle: model.device?.name,
      onClose: _cancel,
      child: _body(
        context,
        installing,
        controller is GenericTvController ? controller.installProgress : null,
      ),
      footer: AppSheetActions(
        primary: OutlinedButton(
          onPressed: _cancel,
          child: Text(
            journeyText(context, 'Cancel connection', 'Cancelar conexão'),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    bool installing,
    double? progress,
  ) => Column(
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
              ? journeyText(
                  context,
                  'The remote will connect automatically when the TV is ready.',
                  'O controle se conectará automaticamente quando a TV estiver pronta.',
                )
              : journeyText(
                  context,
                  'Keep the TV on and accept its connection request.',
                  'Mantenha a TV ligada e aceite a solicitação de conexão.',
                ),
          textAlign: TextAlign.center,
        ),
    ],
  );
}
