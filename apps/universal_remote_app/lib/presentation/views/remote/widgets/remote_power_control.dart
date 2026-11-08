import 'package:flutter/material.dart';

import '../viewmodels/remote_viewmodel.dart';

class RemotePowerControl extends StatelessWidget {
  const RemotePowerControl({super.key, required this.model});
  final RemoteViewModel model;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: model.offline && model.canWake
        ? 'Turn on TV'
        : model.canPowerOff
        ? 'Power off'
        : 'Power unavailable',
    onPressed: model.busy ? null : _action(context),
    icon: const Icon(Icons.power_settings_new),
  );
  VoidCallback? _action(BuildContext context) {
    if (model.offline && model.canWake) {
      return model.wake;
    }
    if (model.canPowerOff) {
      return () => model.powerOff(context);
    }
    return () => model.showStatus(context);
  }
}
