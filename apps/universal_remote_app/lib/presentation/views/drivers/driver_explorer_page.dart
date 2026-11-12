import 'package:flutter/material.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';

import 'driver_explorer_state.dart';

/// Settings → Drivers: provider families from the verified cached catalog.
class DriverExplorerPage extends StatefulWidget {
  const DriverExplorerPage({super.key, this.drivers});

  final IntegrationService? drivers;

  @override
  State<DriverExplorerPage> createState() => DriverExplorerState();
}
