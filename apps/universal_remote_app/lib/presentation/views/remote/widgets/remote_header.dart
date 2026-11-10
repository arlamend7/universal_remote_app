import 'package:flutter/material.dart';

import '../viewmodels/remote_viewmodel.dart';
import 'remote_power_control.dart';

class RemoteHeader extends StatelessWidget {
  const RemoteHeader({super.key, required this.model});
  final RemoteViewModel model;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model.sessionChanges,
    builder: (context, _) => _header(context),
  );
  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8.0),
    child: Row(
      children: [
        Expanded(child: _device(context)),
        _menu(context),
        _status(context),
        RemotePowerControl(model: model),
      ],
    ),
  );
  Widget _device(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: model.busy ? null : () => model.switchDevice(context),
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.expand_more, size: 20),
      label: Text(
        model.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
  Widget _status(BuildContext context) => IconButton(
    tooltip: model.error != null && !model.offline
        ? 'Action failed'
        : model.status,
    onPressed: model.isPairing ? null : () => model.showStatus(context),
    icon: Icon(
      model.error != null ? Icons.info_outline : Icons.circle,
      size: model.error != null ? 18 : 7,
      color: model.offline
          ? Theme.of(context).colorScheme.outline
          : Theme.of(context).colorScheme.primary,
    ),
  );
  Widget _menu(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Remote options',
    icon: const Icon(Icons.more_horiz),
    onSelected: (choice) => model.menu(context, choice),
    itemBuilder: (_) => [
      const PopupMenuItem(value: 'layout', child: Text('Customize remote')),
      if (model.canOpenTvSettings)
        const PopupMenuItem(
          value: 'tv-settings',
          child: Text('Open TV settings'),
        ),
      if (model.canOpenAccessorySettings)
        const PopupMenuItem(
          value: 'accessories',
          child: Text('Bluetooth & accessories'),
        ),
      const PopupMenuItem(value: 'details', child: Text('View details')),
    ],
  );
}
