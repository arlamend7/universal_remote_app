import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import 'device_pairing_state.dart';

class DevicePairingPage extends StatefulWidget {
  const DevicePairingPage({
    super.key,
    required this.dependencies,
    required this.device,
  });

  final AppDependencies dependencies;
  final RemoteDevice device;

  @override
  State<DevicePairingPage> createState() => DevicePairingState();
}
