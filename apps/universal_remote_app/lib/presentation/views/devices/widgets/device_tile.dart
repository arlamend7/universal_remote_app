import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../viewmodels/devices_viewmodel.dart';

class DeviceTile extends StatelessWidget {
  const DeviceTile({super.key, required this.model, required this.device});

  final DevicesViewModel model;
  final RemoteDevice device;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = model.isConnected(device);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: active
            ? colors.primary.withValues(alpha: .40)
            : colors.outlineVariant.withValues(alpha: .55),
      ),
    );
    return Material(
      shape: shape,
      clipBehavior: Clip.antiAlias,
      color: _surface(colors, active),
      child: InkWell(
        onTap: () => model.onConnect(device),
        child: _content(context),
      ),
    );
  }

  Color _surface(ColorScheme colors, bool active) => active
      ? Color.alphaBlend(
          colors.primary.withValues(alpha: .08),
          colors.surfaceContainerHigh,
        )
      : colors.surfaceContainerLow;

  Widget _content(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
    child: Row(
      children: [
        _badge(Theme.of(context).colorScheme),
        const SizedBox(width: 12),
        Expanded(child: _summary(context)),
        _quickAction(),
        _menu(context),
      ],
    ),
  );

  Widget _badge(ColorScheme colors) {
    final statusColor = _statusColor(colors);
    final active = model.isConnected(device);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active
                ? colors.primary.withValues(alpha: .12)
                : colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withValues(alpha: .40)),
          ),
          child: Icon(Icons.tv_outlined, size: 20, color: statusColor),
        ),
        PositionedDirectional(top: -2, end: -2, child: _statusDot(colors)),
      ],
    );
  }

  Widget _statusDot(ColorScheme colors) => Container(
    width: 11,
    height: 11,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _statusColor(colors),
      border: Border.all(color: colors.surface, width: 2),
    ),
  );

  Widget _summary(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          device.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        _metadata(theme),
      ],
    );
  }

  Widget _metadata(ThemeData theme) {
    final platform = model.platformOf(device);
    final address = device.endpoints.firstOrNull?.host;
    final details = [
      if (platform != null && platform.isNotEmpty) platform,
      if (address != null && address.isNotEmpty) address,
    ];
    final style = theme.textTheme.bodySmall;
    return Text.rich(
      TextSpan(
        style: style?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        children: [
          if (details.isNotEmpty) TextSpan(text: details.join(' • ')),
          // TextSpan(
          //   text: _statusLabel,
          //   style: TextStyle(color: _statusColor(theme.colorScheme)),
          // ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  String get _statusLabel => switch (model.stateOf(device)) {
    DeviceConnectionState.connected => 'Active',
    DeviceConnectionState.connecting => 'Connecting',
    DeviceConnectionState.pairing => 'Pairing',
    DeviceConnectionState.reconnecting => 'Waking',
    DeviceConnectionState.disconnected => 'Not connected',
  };

  Color _statusColor(ColorScheme colors) => switch (model.stateOf(device)) {
    DeviceConnectionState.connected => colors.primary,
    DeviceConnectionState.connecting ||
    DeviceConnectionState.pairing ||
    DeviceConnectionState.reconnecting => colors.tertiary,
    DeviceConnectionState.disconnected => colors.onSurfaceVariant,
  };

  Widget _quickAction() {
    if (model.isConnected(device)) {
      return IconButton(
        tooltip: 'Open remote',
        icon: const Icon(Icons.arrow_forward, size: 18),
        onPressed: () => model.onConnect(device),
      );
    }
    if (model.canWake(device)) {
      return IconButton(
        tooltip: 'Wake device',
        icon: const Icon(Icons.power_settings_new, size: 18),
        onPressed: () => model.onWake(device),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _menu(BuildContext context) => PopupMenuButton<String>(
    tooltip: '${device.name} options',
    icon: Icon(
      Icons.more_vert,
      size: 19,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    onSelected: (choice) => model.menu(context, device, choice),
    itemBuilder: (_) => [
      const PopupMenuItem(value: 'details', child: Text('View details')),
      const PopupMenuItem(value: 'layout', child: Text('Customize remote')),
    ],
  );
}
