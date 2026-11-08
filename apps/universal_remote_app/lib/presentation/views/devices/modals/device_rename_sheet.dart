import 'package:flutter/material.dart';

import 'device_rename_state.dart';

class DeviceRenameSheet extends StatefulWidget {
  const DeviceRenameSheet({super.key, required this.name});
  final String name;
  @override
  State<DeviceRenameSheet> createState() => DeviceRenameState();
}
