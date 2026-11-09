import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart';

import '../viewmodels/settings_viewmodel.dart';

class PreferenceSettings extends StatelessWidget {
  const PreferenceSettings({super.key, required this.model});

  final SettingsViewModel model;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        _switch(
          context,
          'Sound & Haptics',
          Icons.vibration,
          model.feedback,
          (value) => model.setFeedback(context, value),
        ),
        if (model.supportsScreenAwake)
          _switch(
            context,
            'Keep Screen Awake',
            Icons.screen_lock_portrait,
            model.screenAwake,
            (value) => model.setScreenAwake(context, value),
          ),
        _switch(
          context,
          'Auto-Reconnect',
          Icons.sync,
          model.autoReconnect,
          (value) => model.setAutoReconnect(context, value),
        ),
        ListTile(
          leading: _icon(context, Icons.help_outline),
          title: const Text('Documentation & Support'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _help(context),
        ),
      ],
    ),
  );

  Widget _switch(
    BuildContext context,
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SwitchListTile.adaptive(
    secondary: _icon(context, icon),
    title: Text(label),
    value: value,
    onChanged: onChanged,
  );

  Widget _icon(BuildContext context, IconData icon) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Icon(icon, size: 20),
  );

  Future<void> _help(BuildContext context) => showAppModal<void>(
    context,
    builder: (sheetContext) => AppSheet(
      title: 'Documentation & Support',
      child: ListenableBuilder(listenable: model.changes, builder: _support),
    ),
  );

  Widget _support(BuildContext context, Widget? child) => Column(
    children: [
      const Text(
        'Keep your TV and this device on the same network. Use Nearby or connect by IP, then approve pairing on the TV. If discovery fails, open Search details to copy diagnostics.',
      ),
      _switch(
        context,
        'Diagnostics',
        Icons.monitor_heart_outlined,
        model.diagnostics,
        (value) => model.setDiagnostics(context, value),
      ),
    ],
  );
}
