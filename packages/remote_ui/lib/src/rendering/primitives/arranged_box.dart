import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

/// Centers an item's elements at their natural footprint inside whatever
/// space the grid gives the item.
///
/// The natural footprint is the definition's default size, transposed when
/// the user's Position differs from the definition's own arrangement. A bigger
/// card adds space around the elements instead of stretching or rearranging
/// them; a smaller one shrinks them to fit.
class ArrangedBox extends StatelessWidget {
  const ArrangedBox({
    super.key,
    required this.definition,
    required this.item,
    required this.child,
  });
  final RemoteItemDefinition<Object> definition;
  final GridItem item;
  final Widget child;

  static const _gap = SquareGridMetrics.gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _layout);

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    final cells = _naturalCells;
    final width = _extent(constraints.maxWidth, item.w, cells.width);
    final height = _extent(constraints.maxHeight, item.h, cells.height);
    return Center(
      child: SizedBox(width: width, height: height, child: child),
    );
  }

  ({int width, int height}) get _naturalCells {
    final canonical = definition.defaultPosition ?? definition.axis;
    if (item.arrangement == canonical) {
      return (width: definition.width, height: definition.height);
    }
    return (width: definition.height, height: definition.width);
  }

  /// The smaller of the space available and [cells] grid cells, measured from
  /// the cell size the item was given along that side.
  double _extent(double available, int span, int cells) {
    if (!available.isFinite) {
      return available;
    }
    final cell = (available + _gap) / span - _gap;
    final natural = cells * (cell + _gap) - _gap;
    return math.max(0, math.min(available, natural));
  }
}
