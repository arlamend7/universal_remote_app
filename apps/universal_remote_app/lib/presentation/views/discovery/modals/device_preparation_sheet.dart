import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart';

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
  return AppSheet(
    title: 'Find Nearby Devices',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Semantics(
          label: 'Preparation, step 1 of 4',
          child: const LinearProgressIndicator(value: .25),
        ),
        TvPreparationCard(
          step: 1,
          icon: Icons.tv_outlined,
          title: 'Check that your TV is on',
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: confirmed,
            onChanged: onConfirm,
            title: Text('My TV is on'),
          ),
        ),
        TvPreparationCard(
          step: 2,
          icon: Icons.wifi,
          title: 'Check your network',
          child: Text(
            'Use the same local network. Your TV can use Wi-Fi or Ethernet.',
          ),
        ),
      ],
    ),
    footer: AppSheetActions(
      secondary: OutlinedButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('Connect by IP'),
      ),
      primary: FilledButton(
        onPressed: confirmed ? () => Navigator.pop(context, true) : null,
        child: Text('Search for devices'),
      ),
    ),
  );
}
