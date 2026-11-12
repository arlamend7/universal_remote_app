import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../../shared/localization/journey_text.dart';
import '../widgets/tv_preparation_card.dart';
import 'device_preparation_state.dart';

class DevicePreparationSheet extends StatefulWidget {
  const DevicePreparationSheet({super.key});

  @override
  State<DevicePreparationSheet> createState() => DevicePreparationState();
}

Widget preparationContent(
  BuildContext context, {
  required bool confirmed,
  required ValueChanged<bool?> onConfirm,
}) {
  String tr(String en, String pt) => journeyText(context, en, pt);
  return AppSheet(
    title: tr('Find Nearby Devices', 'Encontrar dispositivos próximos'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Semantics(
          label: tr('Preparation, step 1 of 4', 'Preparação, etapa 1 de 4'),
          child: const LinearProgressIndicator(value: .25),
        ),
        TvPreparationCard(
          step: 1,
          icon: Icons.tv_outlined,
          title: tr(
            'Check that your TV is on',
            'Verifique se a TV está ligada',
          ),
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: confirmed,
            onChanged: onConfirm,
            title: Text(tr('My TV is on', 'Minha TV está ligada')),
          ),
        ),
        TvPreparationCard(
          step: 2,
          icon: Icons.wifi,
          title: tr('Check your network', 'Confira a conexão de rede'),
          child: Text(
            tr(
              'Use the same local network. Your TV can use Wi-Fi or Ethernet.',
              'Use a mesma rede local. A TV pode usar Wi-Fi ou Ethernet.',
            ),
          ),
        ),
      ],
    ),
    footer: AppSheetActions(
      secondary: OutlinedButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(tr('Connect by IP', 'Conectar por IP')),
      ),
      primary: FilledButton(
        onPressed: confirmed ? () => Navigator.pop(context, true) : null,
        child: Text(tr('Search for devices', 'Buscar dispositivos')),
      ),
    ),
  );
}
