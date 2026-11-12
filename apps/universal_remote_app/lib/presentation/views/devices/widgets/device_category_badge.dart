import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../shared/themes/device_status_colors.dart';

class DeviceCategoryBadge extends StatelessWidget {
  const DeviceCategoryBadge({
    super.key,
    required this.category,
    required this.connected,
    required this.possiblyAwake,
    this.showStatus = true,
  });

  final DeviceCategory category;
  final bool connected;
  final bool possiblyAwake;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (!showStatus) {
      return _iconBox(colors);
    }
    return Semantics(
      label: connected
          ? 'Connected'
          : possiblyAwake
          ? 'Possibly awake'
          : 'Unknown or out of range',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _iconBox(colors),
          PositionedDirectional(top: -3, end: -3, child: _dot(theme)),
        ],
      ),
    );
  }

  Widget _iconBox(ColorScheme colors) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: connected ? colors.primaryContainer : colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: connected ? colors.primary : colors.outlineVariant,
      ),
    ),
    child: Icon(
      _icon,
      size: 22,
      color: connected ? colors.primary : colors.onSurfaceVariant,
    ),
  );

  Widget _dot(ThemeData theme) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _statusColor(theme.brightness),
      border: Border.all(color: theme.colorScheme.surface, width: 2),
    ),
  );

  Color _statusColor(Brightness brightness) {
    if (connected) {
      return DeviceStatusColors.connected(brightness);
    }
    return possiblyAwake
        ? DeviceStatusColors.possiblyAwake(brightness)
        : DeviceStatusColors.unknown(brightness);
  }

  IconData get _icon => switch (category) {
    DeviceCategory.television => Icons.tv_outlined,
    DeviceCategory.airConditioner => Icons.ac_unit,
    DeviceCategory.mediaPlayer => Icons.play_circle_outline,
    DeviceCategory.speaker => Icons.speaker_outlined,
    DeviceCategory.light => Icons.lightbulb_outline,
    DeviceCategory.fan => Icons.air,
    DeviceCategory.projector => Icons.videocam_outlined,
    DeviceCategory.unknown => Icons.devices_other_outlined,
  };
}
