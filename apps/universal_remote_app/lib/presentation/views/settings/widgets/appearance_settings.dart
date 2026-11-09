import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../../../shared/themes/app_themes.dart';
import '../modals/accent_picker.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'accent_swatches.dart';

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key, required this.model});

  final SettingsViewModel model;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: _content(context),
    ),
  );

  Widget _content(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LayoutBuilder(builder: _theme),
      const SizedBox(height: 10),
      const Divider(height: 1),
      _accent(context),
    ],
  );

  Widget _theme(BuildContext context, BoxConstraints constraints) {
    if (constraints.maxWidth < 270 ||
        MediaQuery.textScalerOf(context).scale(14) > 18) {
      return _themeDropdown(context);
    }
    return Row(
      children: [
        const Expanded(child: Text('Theme')),
        _segments(context),
      ],
    );
  }

  Widget _themeDropdown(BuildContext context) =>
      DropdownButtonFormField<ThemeMode>(
        initialValue: model.theme,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Theme'),
        items: [
          for (final mode in ThemeMode.values)
            DropdownMenuItem(value: mode, child: Text(_themeLabel(mode))),
        ],
        onChanged: (value) => model.setTheme(context, value),
      );

  Widget _segments(BuildContext context) => SegmentedButton<ThemeMode>(
    segments: [
      for (final mode in ThemeMode.values)
        ButtonSegment(value: mode, label: Text(_themeLabel(mode))),
    ],
    selected: {model.theme},
    showSelectedIcon: false,
    onSelectionChanged: (selection) => model.setTheme(context, selection.first),
  );

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Auto',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  Widget _accent(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        InkWell(
          onTap: () => _pickAccent(context),
          child: _accentHeading(context),
        ),
        AccentSwatches(
          value: model.accent,
          onSelected: (value) => model.setAccent(context, value),
          custom: () => _pickAccent(context),
        ),
      ],
    ),
  );

  Widget _accentHeading(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Wrap(
      spacing: 10,
      alignment: WrapAlignment.spaceBetween,
      children: [
        const Text('Accent Color'),
        Text(
          _accentName,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ],
    ),
  );

  String get _accentName =>
      [
        ...AppThemes.quickAccents,
        ...AppThemes.accents,
      ].where((accent) => accent.value == model.accent).firstOrNull?.name ??
      'Custom Color';

  Future<void> _pickAccent(BuildContext context) async {
    final accent = await showAppModal<int>(
      context,
      builder: (_) => AccentPicker(initialValue: model.accent),
    );
    if (context.mounted && accent != null && accent != model.accent) {
      await model.setAccent(context, accent);
    }
  }
}
