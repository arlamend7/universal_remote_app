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
    final minimum = item.resizeFloor;
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
      onResize: _commit,
      child: GridItemPreview(
        item: item,
        dependencies: dependencies,
        device: model.device,
        sample: true,
        sampleAppTargets: false,
      ),
    );
  }

  /// Re-resolves the released size (the resolver is deterministic) so the
  /// committed item also carries any Position switch the drag implied.
  void _commit(ResizeCandidate candidate) {
    final resolved = model.resolveDrag(item, candidate.width, candidate.height);
    if (resolved != null) {
      model.applyResize(resolved);
    }
  }

  /// The shared resolver's answer for a requested size, as an offset from
  /// where the item stands.
  ResizeCandidate? _resolve(int width, int height) {
    final resolved = model.resolveDrag(item, width, height);
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
