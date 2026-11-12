import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import 'device_discovery_state.dart';

class DeviceDiscoveryPage extends StatefulWidget {
  const DeviceDiscoveryPage({super.key, required this.dependencies});
  final AppDependencies dependencies;
  @override
  State<DeviceDiscoveryPage> createState() => DeviceDiscoveryState();
}
