import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../devices/widgets/setup_device_row.dart';

class DiscoveredDeviceTile extends StatelessWidget {
  const DiscoveredDeviceTile({
    super.key,
    required this.device,
    required this.subtitle,
    required this.onConnect,
    required this.onDetails,
  });

  final RemoteDevice device;
  final String subtitle;
  final VoidCallback? onConnect;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => SetupDeviceRow(
    device: device,
    subtitle: subtitle,
    onTap: onDetails,
    iconTooltip: 'Device details',
    trailing: FilledButton.tonal(
      onPressed: onConnect,
      child: const Text('Connect'),
    ),
  );
}
