import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../viewmodels/devices_viewmodel.dart';
import 'device_tile.dart';

class DeviceListSection extends StatelessWidget {
  const DeviceListSection({super.key, required this.model});

  final DevicesViewModel model;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(context),
      const SizedBox(height: 8),
      if (model.saved.isEmpty) _empty(context),
      ...model.saved.map(_card),
    ],
  );

  Widget _heading(BuildContext context) {
    final theme = Theme.of(context);
    final count = model.connectedCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(
            'CONFIGURED DISPLAYS (${model.saved.length})',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: .8,
              fontWeight: FontWeight.w700,
            ),
          ),
          _connectedCount(theme, count),
        ],
      ),
    );
  }

  Widget _connectedCount(ThemeData theme, int count) {
    final colors = theme.colorScheme;
    final color = count > 0 ? colors.primary : colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Icon(Icons.circle, color: color, size: 6),
        Text(
          '$count Connected',
          style: theme.textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _empty(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'No displays configured yet. Use Nearby to find a TV or IP to enter its address.',
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _card(RemoteDevice device) => Padding(
    key: ValueKey(device.id),
    padding: const EdgeInsets.only(bottom: 8),
    child: DeviceTile(model: model, device: device),
  );
}
