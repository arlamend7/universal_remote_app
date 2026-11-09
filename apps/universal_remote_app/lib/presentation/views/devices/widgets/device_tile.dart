import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../viewmodels/devices_viewmodel.dart';
import 'device_category_badge.dart';

class DeviceTile extends StatelessWidget {
  const DeviceTile({
    super.key,
    required this.model,
    required this.device,
    required this.onTap,
    required this.onLongPress,
  });

  final DevicesViewModel model;
  final RemoteDevice device;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = model.isConnected(device);
    final border = BorderSide(
      color: active ? colors.primary : colors.outlineVariant,
    );
    return Material(
      shape: Border(top: border, bottom: border),
      color: active ? colors.surfaceContainerHigh : colors.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(
      spacing: 8,
      children: [
        DeviceCategoryBadge(
          category: device.category,
          connected: model.isConnected(device),
          possiblyAwake: model.possiblyAwake(device),
        ),
        Expanded(child: _summary(context)),
        _quickAction(),
        _info(context),
      ],
    ),
  );

  Widget _summary(BuildContext context) {
    final theme = Theme.of(context);
    final platform = model.platformOf(device);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 3,
      children: [
        Text(
          device.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (platform != null && platform.isNotEmpty) _platform(theme, platform),
      ],
    );
  }

  Widget _platform(ThemeData theme, String platform) {
    final colors = theme.colorScheme;
    final active = model.isConnected(device);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? colors.primaryContainer : colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        child: Text(
          platform,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: active ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _quickAction() {
    if (model.isConnected(device)) {
      return IconButton.filledTonal(
        tooltip: 'Open remote',
        icon: const Icon(Icons.arrow_forward, size: 18),
        onPressed: () => model.onConnect(device),
      );
    }
    if (model.canWake(device)) {
      return IconButton.filledTonal(
        tooltip: 'Wake device',
        icon: const Icon(Icons.power_settings_new, size: 18),
        onPressed: () => model.onWake(device),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _info(BuildContext context) => IconButton.outlined(
    tooltip: '${device.name} info',
    icon: const Icon(Icons.info_outline, size: 20),
    onPressed: () => model.info(context, device),
  );
}
