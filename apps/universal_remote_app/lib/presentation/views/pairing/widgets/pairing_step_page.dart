import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../devices/widgets/setup_device_row.dart';
import '../../../shared/widgets/setup/setup_step_page.dart';

class PairingStepPage extends StatelessWidget {
  const PairingStepPage({
    super.key,
    required this.device,
    required this.onBack,
    required this.body,
    this.primary,
    this.secondary,
    this.footerLink,
    this.connected = false,
  });

  final RemoteDevice device;
  final VoidCallback onBack;
  final Widget body;
  final Widget? primary;
  final Widget? secondary;
  final Widget? footerLink;
  final bool connected;

  @override
  Widget build(BuildContext context) => SetupStepPage(
    step: 3,
    title: 'Pairing',
    onBack: onBack,
    banner: SetupDeviceRow(
      device: device,
      subtitle: device.endpoints.firstOrNull?.host ?? '',
      connected: connected,
    ),
    body: body,
    primary: primary,
    secondary: secondary,
    footerLink: footerLink,
  );
}
