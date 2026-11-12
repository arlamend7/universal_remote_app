import 'package:flutter/material.dart';

import '../../../widgets/layout/content_page.dart';
import '../../../widgets/layout/page_title.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/appearance_settings.dart';
import '../widgets/preference_settings.dart';

class SettingsViewport extends StatelessWidget {
  const SettingsViewport({super.key, required this.model});

  final SettingsViewModel model;

  @override
  Widget build(BuildContext context) => ContentPage(
    maxWidth: 480,
    padding: const EdgeInsets.fromLTRB(17, 16, 17, 24),
    children: [
      PageTitle(title: 'Settings', leading: _activeDevice(context)),
      const SizedBox(height: 20),
      _heading(context, 'Appearance'),
      AppearanceSettings(model: model),
      const SizedBox(height: 22),
      _heading(context, 'Preferences'),
      PreferenceSettings(model: model),
      const SizedBox(height: 24),
      Text(
        'Universal Remote',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );

  Widget _activeDevice(BuildContext context) {
    final device = model.connectedDevice;
    if (device == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Row(
      spacing: 6,
      children: [
        Icon(Icons.circle, size: 8, color: theme.colorScheme.primary),
        Flexible(
          child: Text(
            '${device.toUpperCase()} ACTIVE',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ),
      ],
    );
  }

  Widget _heading(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      title.toUpperCase(),
      semanticsLabel: title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1),
    ),
  );
}
