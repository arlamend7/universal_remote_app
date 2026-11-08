import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../../items/standard_items.dart';
import '../viewmodels/grid_remote_viewmodel.dart';
import 'grid_button.dart';

class GridUtilityWidget extends StatelessWidget {
  const GridUtilityWidget({super.key, required this.item, required this.model});
  final GridItem item;
  final GridRemoteViewModel model;
  @override
  Widget build(BuildContext context) => switch (item.kind) {
    GridWidgetKind.power => _button(
      label: item.config['label'] ?? 'Power off',
      icon: _registeredIcon,
      onPressed: model.remote.canPowerOff
          ? () => model.power(context, item)
          : null,
    ),
    GridWidgetKind.wake => _button(
      label: 'Wake device',
      icon: _registeredIcon,
      onPressed: model.remote.canWake
          ? () => item.element(wakeAction).onPressed(model.remote, null)
          : null,
    ),
    GridWidgetKind.connect => _button(
      label: model.remote.offline ? 'Connect' : 'Disconnect',
      icon: _registeredIcon,
      onPressed: () =>
          item.element(connectAction).onPressed(model.remote, null),
    ),
    GridWidgetKind.keyboard => _button(
      label: 'Keyboard',
      icon: _registeredIcon,
      onPressed: model.ready && model.supports(RemoteCapability.textInput)
          ? () => model.keyboard(
              context,
              KeyboardConfiguration.fromSettings(item.config),
            )
          : null,
    ),
    GridWidgetKind.sleep => ValueListenableBuilder(
      valueListenable: model.remote.sleepDeadline,
      builder: (context, deadline, child) => _button(
        label: deadline == null
            ? 'Sleep ${item.config['minutes'] ?? '30'} min'
            : 'Cancel sleep timer',
        icon: _registeredIcon,
        onPressed: model.remote.canPowerOff
            ? () => model.sleep(context, item, deadline)
            : null,
      ),
    ),
    GridWidgetKind.voice => _optionalAction(
      TvItems.voice,
      RemoteCapability.voice,
    ),
    GridWidgetKind.gameMode => _optionalAction(
      TvItems.gameMode,
      RemoteCapability.gameMode,
    ),
    GridWidgetKind.watch => _optionalAction(
      TvItems.watch,
      RemoteCapability.watch,
    ),
    _ => _button(
      label: 'View details',
      icon: _registeredIcon,
      onPressed: () =>
          item.element(detailsAction).onPressed(model.remote, context),
    ),
  };
  IconData get _registeredIcon => model.iconOf(
    RemoteItemRegistry.resolve(item.kind).elements.first,
    item.kind,
  );

  Widget _optionalAction(
    RemoteAction<TvRemoteDevice, Null> reference,
    RemoteCapability capability,
  ) {
    final action = item.element(reference);
    final definition = RemoteItemRegistry.resolve(item.kind);
    return _button(
      label: definition.name,
      icon: model.iconOf(action, item.kind),
      onPressed: model.ready && model.supports(capability)
          ? () => action.onPressed(model, null)
          : null,
    );
  }

  Widget _button({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
  }) => GridButton(
    appearance: item.config,
    label: item.config['label'] ?? label,
    icon: icon,
    showLabel: item.config['showLabel'] != 'false',
    onPressed: onPressed,
  );
}
