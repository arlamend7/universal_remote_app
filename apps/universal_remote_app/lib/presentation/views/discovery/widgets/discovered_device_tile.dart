import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../devices/widgets/device_category_badge.dart';
import '../../devices/widgets/device_row_surface.dart';

class DiscoveredDeviceTile extends StatelessWidget {
  const DiscoveredDeviceTile({
    super.key,
    required this.device,
    required this.subtitle,
    required this.selected,
    required this.onSelect,
    required this.onDetails,
  });

  final RemoteDevice device;
  final String subtitle;
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: DeviceRowSurface(
      highlighted: selected,
      onTap: onSelect,
      child: ListTile(
        leading: DeviceCategoryBadge(
          category: device.category,
          connected: false,
          possiblyAwake: false,
          showStatus: false,
        ),
        title: Text(device.name),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: _trailing(context),
      ),
    ),
  );

  Widget _trailing(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Device details',
        onPressed: onDetails,
        icon: const Icon(Icons.info_outline),
      ),
      Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
    ],
  );
}
