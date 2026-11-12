import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'device_category_badge.dart';
import 'device_row_surface.dart';

class SetupDeviceRow extends StatelessWidget {
  const SetupDeviceRow({
    super.key,
    required this.device,
    required this.subtitle,
    this.connected = false,
    this.onTap,
    this.trailing,
    this.iconTooltip,
  });

  final RemoteDevice device;
  final String subtitle;
  final bool connected;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? iconTooltip;

  @override
  Widget build(BuildContext context) => DeviceRowSurface(
    highlighted: false,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _badge(),
        title: Text(
          device.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing:
            trailing ??
            (connected ? const Chip(label: Text('Connected')) : null),
      ),
    ),
  );

  Widget _badge() {
    final icon = DeviceCategoryBadge(
      category: device.category,
      connected: connected,
      possiblyAwake: false,
      showStatus: false,
    );
    final tooltip = iconTooltip;
    return tooltip == null ? icon : Tooltip(message: tooltip, child: icon);
  }
}
