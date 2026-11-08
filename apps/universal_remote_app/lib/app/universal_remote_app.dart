import 'package:flutter/material.dart';

import 'app_dependencies.dart';
import 'universal_remote_app_state.dart';

class UniversalRemoteApp extends StatefulWidget {
  const UniversalRemoteApp({super.key, required this.dependencies});
  final AppDependencies dependencies;
  @override
  State<UniversalRemoteApp> createState() => UniversalRemoteAppState();
}
