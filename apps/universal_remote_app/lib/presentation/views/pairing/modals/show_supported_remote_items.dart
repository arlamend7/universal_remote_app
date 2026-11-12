import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../routes/open_remote_editor.dart';
import '../../remote/viewmodels/remote_viewmodel.dart';
import '../widgets/supported_remote_items.dart';

Future<bool> showSupportedRemoteItems(
  BuildContext context,
  AppDependencies dependencies,
  RemoteDevice device,
) async {
  final remote = RemoteViewModel(dependencies);
  final openRemote = await showAppModal<bool>(
    context,
    builder: (context) => AppSheet(
      title: 'Supported controls',
      subtitle: device.name,
      child: SupportedRemoteItems(remote: remote),
      footer: AppSheetActions(
        secondary: OutlinedButton(
          onPressed: () => openRemoteEditor(context, dependencies, device),
          child: Text('Customize remote'),
        ),
        primary: FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Start controlling'),
        ),
      ),
    ),
  );
  return openRemote ?? false;
}
