import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../viewmodels/devices_viewmodel.dart';

class DeviceTile extends StatelessWidget {
  const DeviceTile({super.key, required this.model, required this.device});
  final DevicesViewModel model;
  final RemoteDevice device;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: _tile(context),
  );
  Widget _tile(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minTileHeight: 60,
    leading: const Icon(Icons.tv_outlined, size: 22),
    title: Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    onTap: () => model.onConnect(device),
    trailing: _trailing(context),
  );
  Widget _trailing(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [_status(context), _menu(context)],
  );
  Widget _status(BuildContext context) => Tooltip(
    message: model.isConnected(device) ? 'Connected' : 'Offline',
    child: Icon(
      Icons.circle,
      size: 7,
      semanticLabel: model.isConnected(device) ? 'Connected' : 'Offline',
      color: model.isConnected(device)
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.outline,
    ),
  );
  Widget _menu(BuildContext context) => PopupMenuButton<String>(
    tooltip: '${device.name} options',
    icon: const Icon(Icons.more_horiz),
    onSelected: (choice) => model.menu(context, device, choice),
    itemBuilder: (_) => [
      const PopupMenuItem(value: 'details', child: Text('View details')),
      const PopupMenuItem(value: 'layout', child: Text('Customize remote')),
    ],
  );
}
