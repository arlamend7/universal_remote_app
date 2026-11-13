import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'grid_item_preview.dart';

class GridEditTile extends StatelessWidget {
  const GridEditTile({
    super.key,
    required this.item,
    required this.model,
    this.dependencies,
    this.onEdit,
  });
  final GridItem item;
  final GridEditorViewModel model;
  final RemoteEditorHost? dependencies;
  final ValueChanged<GridItem>? onEdit;
  @override
  Widget build(BuildContext context) {
    final room = model.roomFor(item);
    return UniversalRemoteItem(
      id: item.id,
      label: item.config['label'] ?? item.definition.name,
      width: item.w,
      height: item.h,
      minimumWidth: item.definition.minimumWidth,
      minimumHeight: item.definition.minimumHeight,
      maximumWidth: room.width,
      maximumHeight: room.height,
      style: item.style,
      enabled: !model.saving,
      selected: model.selected == item.id,
      onEdit: () {
        model.select(item.id);
        onEdit?.call(item);
      },
      onRemove: () => model.remove(item.id),
      canResize: (w, h) => model.canReplace(item.copy(w: w, h: h)),
      onResize: (w, h) => model.resize(item, w, h),
      child: GridItemPreview(
        item: item,
        dependencies: dependencies,
        device: model.device,
        sample: true,
        sampleAppTargets: false,
      ),
    );
  }
}
