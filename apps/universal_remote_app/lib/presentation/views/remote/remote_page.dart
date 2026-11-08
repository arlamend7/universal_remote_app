import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import 'remote_page_state.dart';

class RemotePage extends StatefulWidget {
  const RemotePage({
    super.key,
    required this.dependencies,
    required this.onChooseDevice,
    required this.active,
  });
  final AppDependencies dependencies;
  final VoidCallback onChooseDevice;
  final bool active;
  @override
  State<RemotePage> createState() => RemotePageState();
}
