import 'package:flutter/material.dart';

import '../viewmodels/settings_viewmodel.dart';
import 'accent_swatches.dart';

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key, required this.model});
  final SettingsViewModel model;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      _theme(context),
      const SizedBox(height: 16),
      Text('Accent color', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      AccentSwatches(model: model),
      const SizedBox(height: 12),
      _feedback(context),
      const SizedBox(height: 8),
      _diagnostics(context),
    ],
  );
  Widget _theme(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 300 &&
          MediaQuery.textScalerOf(context).scale(1) > 1.3) {
        return DropdownButtonFormField<ThemeMode>(
          initialValue: model.theme,
          decoration: const InputDecoration(labelText: 'Theme'),
          items: ThemeMode.values
              .map(
                (mode) => DropdownMenuItem(value: mode, child: Text(mode.name)),
              )
              .toList(),
          onChanged: (value) => model.setTheme(context, value),
        );
      }
      return _segments(context);
    },
  );
  Widget _segments(BuildContext context) => SegmentedButton<ThemeMode>(
    segments: const [
      ButtonSegment(value: ThemeMode.system, label: Text('System')),
      ButtonSegment(value: ThemeMode.light, label: Text('Light')),
      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
    ],
    selected: {model.theme},
    showSelectedIcon: false,
    onSelectionChanged: (selection) => model.setTheme(context, selection.first),
  );
  Widget _feedback(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: const Text('Sound and haptics'),
    subtitle: const Text('Click sounds and vibration when you press controls.'),
    value: model.feedback,
    onChanged: (value) => model.setFeedback(context, value),
  );
  Widget _diagnostics(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: const Text('Diagnostics'),
    subtitle: const Text('Local events only; no credentials.'),
    value: model.diagnostics,
    onChanged: (value) => model.setDiagnostics(context, value),
  );
}
