import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import '../../layout/models/square_grid_metrics.dart';
import 'element_view.dart';

/// Draws every element an item definition registers, in order, as a row,
/// column or grid. Elements share space by their slots.
class ElementStrip extends StatelessWidget {
  const ElementStrip({
    super.key,
    required this.definition,
    required this.item,
    required this.model,
  });
  final RemoteItemDefinition<Object> definition;
  final GridItem item;
  final GridRemoteViewModel model;

  Axis get _axis => definition.axisFor(item.w, item.h) == ItemAxis.vertical
      ? Axis.vertical
      : Axis.horizontal;

  /// Adaptive layouts declare elements top to bottom and reverse them when
  /// they run horizontally.
  List<RemoteElement<Object>> get _elements =>
      definition.layout is LinearLayout &&
          (definition.layout as LinearLayout).adaptive &&
          (definition.layout as LinearLayout).reverseWhenHorizontal &&
          _axis == Axis.horizontal
      ? definition.elements.reversed.toList()
      : definition.elements;

  @override
  Widget build(BuildContext context) {
    final layout = definition.layout;
    const gap = SquareGridMetrics.gap;
    final padding = _elements.length > 1
        ? const EdgeInsets.all(gap / 2)
        : EdgeInsets.zero;
    if (layout is ElementGridLayout) {
      return GridView.count(
        padding: padding,
        crossAxisCount: layout.columns,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: ElementGridLayout.aspectRatio,
        children: [for (final element in _elements) _view(element)],
      );
    }
    return Padding(
      padding: padding,
      child: Flex(
        direction: _axis,
        spacing: gap,
        children: [
          for (final element in _elements)
            Expanded(flex: element.slots, child: _view(element)),
        ],
      ),
    );
  }

  Widget _view(RemoteElement<Object> element) => ElementView(
    definition: definition,
    element: element,
    item: item,
    model: model,
    axis: _axis,
  );
}
