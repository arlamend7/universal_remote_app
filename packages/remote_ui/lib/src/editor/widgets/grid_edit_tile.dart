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
  Widget build(BuildContext context) => UniversalRemoteItem(
    id: item.id,
    label: item.config['label'] ?? item.definition.name,
    width: item.w,
    height: item.h,
    quarterTurns: item.quarterTurns,
    style: item.style,
    enabled: !model.saving,
    selected: model.selected == item.id,
    onEdit: () {
      model.select(item.id);
      onEdit?.call(item);
    },
    onRemove: () => model.remove(item.id),
    onResize: (w, h) => model.resize(item, w, h),
    child: GridItemPreview(
      item: item.unrotated,
      dependencies: dependencies,
      device: model.device,
    ),
  );
}
