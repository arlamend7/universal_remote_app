import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'viewmodels/grid_remote_viewmodel.dart';
import 'element_renderer.dart';

/// Feedback updates only the controls that consume it, not canvas geometry.
class GridRemoteItem extends StatelessWidget {
  const GridRemoteItem({super.key, required this.item, required this.model});
  final GridItem item;
  final GridRemoteViewModel model;
  @override
  Widget build(BuildContext context) => StyledItem(
    quarterTurns: item.quarterTurns,
    style: item.style,
    child: Semantics(container: true, child: _content()),
  );

  Widget _content() {
    if (item.isGroup) {
      return ElementRenderer(item: item.unrotated, model: model);
    }
    return ListenableBuilder(
      listenable: _changes,
      builder: (_, _) => ElementRenderer(item: item.unrotated, model: model),
    );
  }

  Listenable get _changes => switch (item.definition.category) {
    RemoteItemCategory.audio ||
    RemoteItemCategory.volume ||
    RemoteItemCategory.mute => model.remote.volumeChanges,
    RemoteItemCategory.channels ||
    RemoteItemCategory.channelArrows => model.remote.contentChanges,
    RemoteItemCategory.information ||
    RemoteItemCategory.activity => Listenable.merge([
      model.remote.contentChanges,
      model.remote.sessionChanges,
    ]),
    RemoteItemCategory.apps || RemoteItemCategory.pinnedApps =>
      Listenable.merge([model.remote.controlsChanges, model.remote.profiles]),
    RemoteItemCategory.media => Listenable.merge([
      model.remote.controlsChanges,
      TvItems.mediaPlaying,
    ]),
    RemoteItemCategory.utilities => Listenable.merge([
      model.remote.controlsChanges,
      model.remote.sleepDeadline,
    ]),
    _ => model.remote.controlsChanges,
  };
}
