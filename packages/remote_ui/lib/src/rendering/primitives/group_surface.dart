import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../../widgets/grid/grid_surface.dart';
import '../grid_remote_item.dart';
import '../viewmodels/grid_remote_viewmodel.dart';

/// A nested grid of child items with an optional title row.
class GroupSurface extends StatelessWidget {
  const GroupSurface({super.key, required this.item, required this.model});
  final GridItem item;
  final GridRemoteViewModel model;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final cell = (constraints.maxHeight - (item.h - 1) * 8) / item.h;
      return Stack(
        children: [
          GridSurface(
            layout: GridLayout(item.children),
            columns: item.w,
            rows: item.h,
            cellHeight: cell,
            itemBuilder: (child) => GridRemoteItem(item: child, model: model),
          ),
          if (item.config['showTitle'] == 'true') _title(cell),
        ],
      );
    },
  );

  Widget _title(double height) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    height: height,
    child: Center(
      child: Text(
        item.config['label'] ?? 'Group',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}
