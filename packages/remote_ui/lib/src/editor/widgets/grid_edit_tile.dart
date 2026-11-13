import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../../widgets/models/resize_candidate.dart';
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
    final minimum = item.minimumSize;
    return UniversalRemoteItem(
      id: item.id,
      label: item.config['label'] ?? item.definition.name,
      width: item.w,
      height: item.h,
      minimumWidth: minimum.width,
      minimumHeight: minimum.height,
      style: item.style,
      enabled: !model.saving,
      selected: model.selected == item.id,
      onEdit: () {
        model.select(item.id);
        onEdit?.call(item);
      },
      onRemove: () => model.remove(item.id),
      resolveResize: _resolve,
      onResize: (candidate) => model.applyResize(
        item.copy(
          x: item.x + candidate.dx,
          y: item.y + candidate.dy,
          w: candidate.width,
          h: candidate.height,
        ),
      ),
      child: GridItemPreview(
        item: item,
        dependencies: dependencies,
        device: model.device,
        sample: true,
        sampleAppTargets: false,
      ),
    );
  }

  /// The shared resolver's answer for a requested size, as an offset from
  /// where the item stands.
  ResizeCandidate? _resolve(int width, int height) {
    final resolved = model.resolveResize(item, width, height);
    if (resolved == null) {
      return null;
    }
    return (
      dx: resolved.x - item.x,
      dy: resolved.y - item.y,
      width: resolved.w,
      height: resolved.h,
    );
  }
}
