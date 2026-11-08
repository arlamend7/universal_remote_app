import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import 'device_discovery_state.dart';

class DeviceDiscoverySheet extends StatefulWidget {
  const DeviceDiscoverySheet({super.key, required this.dependencies});
  final AppDependencies dependencies;
  @override
  State<DeviceDiscoverySheet> createState() => DeviceDiscoveryState();
}
