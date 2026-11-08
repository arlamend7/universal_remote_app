import 'package:flutter/material.dart';

import '../../../widgets/layout/content_page.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/appearance_settings.dart';

class SettingsViewport extends StatelessWidget {
  const SettingsViewport({super.key, required this.model});
  final SettingsViewModel model;
  @override
  Widget build(BuildContext context) => ContentPage(
    maxWidth: 480,
    children: [
      Text('Settings', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 20),
      AppearanceSettings(model: model),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.help_outline),
        title: const Text('Help'),
        onTap: () => _help(context),
      ),
      const SizedBox(height: 24),
      const Text('Universal Remote', textAlign: TextAlign.center),
    ],
  );
  Future<void> _help(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Connect your TV'),
      content: const Text(
        'Keep your TV and this device on the same network. Use Find TVs or connect by IP, then approve pairing on the TV.\n\nControls depend on your TV and audio output. Open View details for connection and capability information.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
