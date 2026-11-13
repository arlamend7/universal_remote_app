import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import 'arranged_box.dart';
import 'element_view.dart';

/// Draws every element an item definition registers, in order, as a row,
/// column or grid. The item's Position picks the direction; its size only
/// decides how much room surrounds the centered elements.
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

  static const _gap = SquareGridMetrics.gap;

  Axis get _axis =>
      item.arrangement == ItemAxis.vertical ? Axis.vertical : Axis.horizontal;

  List<RemoteElement<Object>> get _elements => definition.elements;

  @override
  Widget build(BuildContext context) {
    if (_elements.length < 2) {
      return _single();
    }
    return ArrangedBox(
      definition: definition,
      item: item,
      child: Padding(
        padding: const EdgeInsets.all(_gap / 2),
        child: _arrangement(),
      ),
    );
  }

  /// A lone element is the whole control, so it fills the card.
  Widget _single() {
    if (_elements.isEmpty) {
      return const SizedBox.shrink();
    }
    return _view(_elements.single);
  }

  Widget _arrangement() {
    final layout = definition.layout;
    if (layout is ElementGridLayout) {
      return _grid(layout);
    }
    return Flex(
      direction: _axis,
      spacing: _gap,
      children: [
        for (final element in _elements)
          Expanded(flex: element.slots, child: _view(element)),
      ],
    );
  }

  Widget _grid(ElementGridLayout layout) => GridView.count(
    crossAxisCount: _gridColumns(layout),
    crossAxisSpacing: _gap,
    mainAxisSpacing: _gap,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: ElementGridLayout.aspectRatio,
    children: [for (final element in _elements) _view(element)],
  );

  int _gridColumns(ElementGridLayout layout) {
    final canonical = definition.defaultPosition ?? definition.axis;
    if (!layout.transposable || item.arrangement == canonical) {
      return layout.columns;
    }
    return layout.transposedColumns(_elements.length);
  }

  Widget _view(RemoteElement<Object> element) => ElementView(
    definition: definition,
    element: element,
    item: item,
    model: model,
    axis: _axis,
  );
}
