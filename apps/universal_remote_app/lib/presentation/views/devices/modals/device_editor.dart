import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import 'device_editor_state.dart';

class DeviceEditor extends StatefulWidget {
  const DeviceEditor({super.key, required this.dependencies, this.device});
  final AppDependencies dependencies;
  final RemoteDevice? device;
  @override
  State<DeviceEditor> createState() => DeviceEditorState();
}
