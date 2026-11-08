import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import 'grid_remote_widget.dart';

/// Feedback updates only the controls that consume it, not canvas geometry.
class GridRemoteItem extends StatelessWidget {
  const GridRemoteItem({super.key, required this.item, required this.model});
  final GridItem item;
  final GridRemoteViewModel model;
  @override
  Widget build(BuildContext context) => UniversalRemoteItem.control(
    quarterTurns: item.quarterTurns,
    style: item.style,
    child: Semantics(container: true, child: _content()),
  );

  Widget _content() {
    if (item.kind == GridWidgetKind.group) {
      return GridRemoteWidget(item: item.unrotated, model: model);
    }
    return ListenableBuilder(
      listenable: _changes,
      builder: (_, _) => GridRemoteWidget(item: item.unrotated, model: model),
    );
  }

  Listenable get _changes =>
      switch (WidgetCatalog.definition(item.kind).category) {
        RemoteItemCategory.audio => model.remote.volumeChanges,
        RemoteItemCategory.channels => model.remote.contentChanges,
        RemoteItemCategory.information => Listenable.merge([
          model.remote.contentChanges,
          model.remote.sessionChanges,
        ]),
        RemoteItemCategory.apps => Listenable.merge([
          model.remote.controlsChanges,
          model.remote.profiles,
        ]),
        _ => model.remote.controlsChanges,
      };
}
