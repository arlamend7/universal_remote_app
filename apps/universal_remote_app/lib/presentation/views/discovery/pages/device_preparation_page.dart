import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import 'device_preparation_state.dart';

class DevicePreparationPage extends StatefulWidget {
  const DevicePreparationPage({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<DevicePreparationPage> createState() => DevicePreparationState();
}
