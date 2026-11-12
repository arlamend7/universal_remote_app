import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import 'device_preparation_state.dart';

class DevicePreparationPage extends StatefulWidget {
  const DevicePreparationPage({
    super.key,
    required this.dependencies,
    this.onSetupFinished,
    this.onReplacedByDiscovery,
  });

  final AppDependencies dependencies;

  /// Set for the first connection. The preparation step stays below
  /// discovery and has no Back button.
  final ValueChanged<RemoteDevice?>? onSetupFinished;

  /// Receives the discovery result when searching replaces this step.
  final ValueChanged<Future<RemoteDevice?>>? onReplacedByDiscovery;

  @override
  State<DevicePreparationPage> createState() => DevicePreparationState();
}
