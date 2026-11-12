import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import 'device_preparation_state.dart';

class DevicePreparationPage extends StatefulWidget {
  const DevicePreparationPage({
    super.key,
    required this.dependencies,
    this.onSetupFinished,
    this.openManualAddress = false,
  });

  final AppDependencies dependencies;
  final bool openManualAddress;
  final ValueChanged<RemoteDevice?>? onSetupFinished;

  @override
  State<DevicePreparationPage> createState() => DevicePreparationState();
}
