import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import 'grid_button.dart';

class GridChannelsWidget extends StatelessWidget {
  const GridChannelsWidget({
    super.key,
    required this.item,
    required this.model,
  });
  final GridItem item;
  final GridRemoteViewModel model;
  Widget _up() => GridButton(
    label: 'Next channel',
    icon: Icons.add,
    showLabel: false,
    repeat: item.config['hold'] == 'true',
    onPressed: model.remote.canChangeChannel
        ? () => item.element(TvItems.channelUp).onPressed(model, null)
        : null,
  );
  Widget _down() => GridButton(
    label: 'Previous channel',
    icon: Icons.remove,
    showLabel: false,
    repeat: item.config['hold'] == 'true',
    onPressed: model.remote.canChangeChannel
        ? () => item.element(TvItems.channelDown).onPressed(model, null)
        : null,
  );
  Widget _number() => Text(
    model.remote.content?.channelNumber ?? '—',
    textAlign: TextAlign.center,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
  @override
  Widget build(BuildContext context) {
    if (item.kind == GridWidgetKind.channelDisplay) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: _number()),
          Flexible(
            child: Text(
              model.remote.content?.channelName ?? 'Channel unavailable',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    if (item.w > item.h) {
      return Row(
        children: [
          Expanded(child: _down()),
          _number(),
          Expanded(child: _up()),
        ],
      );
    }
    return Column(
      children: [
        Expanded(child: _up()),
        if (item.kind == GridWidgetKind.channelDisplayRocker) _number(),
        Expanded(child: _down()),
      ],
    );
  }
}
