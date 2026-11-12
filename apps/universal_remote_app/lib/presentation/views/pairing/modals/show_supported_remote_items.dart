import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../routes/open_remote_editor.dart';
import '../../../shared/localization/journey_text.dart';
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
      title: journeyText(
        context,
        'Supported controls',
        'Controles disponíveis',
      ),
      subtitle: device.name,
      child: SupportedRemoteItems(remote: remote),
      footer: AppSheetActions(
        secondary: OutlinedButton(
          onPressed: () => openRemoteEditor(context, dependencies, device),
          child: Text(
            journeyText(context, 'Customize remote', 'Personalizar controle'),
          ),
        ),
        primary: FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            journeyText(context, 'Start controlling', 'Começar a controlar'),
          ),
        ),
      ),
    ),
  );
  return openRemote ?? false;
}
