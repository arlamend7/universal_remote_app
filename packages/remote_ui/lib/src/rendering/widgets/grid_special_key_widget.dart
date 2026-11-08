import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'package:remote_core/remote_core.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import 'grid_button.dart';

class GridSpecialKeyWidget extends StatelessWidget {
  const GridSpecialKeyWidget({
    super.key,
    required this.item,
    required this.model,
  });
  final GridItem item;
  final GridRemoteViewModel model;
  @override
  Widget build(BuildContext context) => GridButton(
    appearance: item.config,
    label: item.config['label'] ?? item.kind.name,
    icon: Icons.keyboard_command_key,
    showLabel: item.config['showLabel'] != 'false',
    onPressed: model.ready && model.supports(RemoteCapability.pointer)
        ? () => item
              .element(TvItems.specialKey)
              .onPressed(model, RemoteKey.values.byName(item.kind.name))
        : null,
  );
}
