import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'package:remote_core/remote_core.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import 'grid_button.dart';

class GridMediaWidget extends StatelessWidget {
  const GridMediaWidget({super.key, required this.item, required this.model});
  final GridItem item;
  final GridRemoteViewModel model;
  @override
  Widget build(BuildContext context) {
    if (item.kind == GridWidgetKind.transport) {
      return Row(
        children: [
          Expanded(child: _button(MediaAction.play)),
          Expanded(child: _button(MediaAction.pause)),
          Expanded(child: _button(MediaAction.stop)),
        ],
      );
    }
    return _button(switch (item.kind) {
      GridWidgetKind.pause => MediaAction.pause,
      GridWidgetKind.stop => MediaAction.stop,
      GridWidgetKind.rewind => MediaAction.rewind,
      GridWidgetKind.forward => MediaAction.fastForward,
      _ => MediaAction.play,
    });
  }

  Widget _button(MediaAction action) => GridButton(
    appearance: item.config,
    label: item.config['label'] ?? action.name,
    showLabel: item.config['showLabel'] != 'false',
    icon: switch (action) {
      MediaAction.play => Icons.play_arrow,
      MediaAction.pause => Icons.pause,
      MediaAction.stop => Icons.stop,
      MediaAction.rewind => Icons.fast_rewind,
      MediaAction.fastForward => Icons.fast_forward,
    },
    onPressed: model.ready && model.supports(RemoteCapability.media)
        ? () => item.element(TvItems.media).onPressed(model, action)
        : null,
  );
}
