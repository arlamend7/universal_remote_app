import 'package:flutter/material.dart';

import 'app/app_bootstrap.dart';
import 'app/universal_remote_app.dart';
import 'presentation/views/startup/startup_error_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final dependencies = await AppBootstrap.initialize();
    runApp(UniversalRemoteApp(dependencies: dependencies));
  } catch (_) {
    // Native storage failures never trigger a plaintext fallback.
    runApp(StartupErrorApp(retry: main));
  }
}
