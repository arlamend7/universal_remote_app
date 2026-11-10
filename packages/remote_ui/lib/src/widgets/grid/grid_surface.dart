import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

/// Shared geometry for edit and runtime. Runtime contributes no frame decoration.
class GridSurface extends StatelessWidget {
  const GridSurface({
    super.key,
    required this.layout,
    required this.itemBuilder,
    this.columns = 4,
    this.rows,
    this.cellHeight,
    this.gap = 8,
    this.columnOffset = 0,
  });
  final GridLayout layout;
  final Widget Function(GridItem) itemBuilder;
  final int columns;
  final int? rows;
  final double? cellHeight;
  final double gap;
  final int columnOffset;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _build);
  Widget _build(BuildContext context, BoxConstraints constraints) {
    final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
    final height =
        cellHeight ??
        math.max(
          width,
          64 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
        );
    final count = rows ?? layout.rows;
    return SizedBox(
      height: count * (height + gap) - gap,
      child: Stack(
        clipBehavior: Clip.none,
        children: layout.items
            .map((item) => _position(item, width, height))
            .toList(),
      ),
    );
  }

  Widget _position(GridItem item, double width, double height) => Positioned(
    key: ValueKey(item.id),
    left: (item.x - columnOffset) * (width + gap),
    top: item.y * (height + gap),
    width: item.w * (width + gap) - gap,
    height: item.h * (height + gap) - gap,
    child: itemBuilder(item),
  );
}
