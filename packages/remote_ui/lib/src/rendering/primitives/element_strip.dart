import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
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
          _axis == Axis.horizontal
      ? definition.elements.reversed.toList()
      : definition.elements;

  @override
  Widget build(BuildContext context) {
    final stream = _streamedChange();
    if (stream == null) {
      return _layout();
    }
    return StreamBuilder<Object?>(
      key: ObjectKey(model.remote.connection.controller),
      stream: stream,
      builder: (_, _) => _layout(),
    );
  }

  /// Elements react to readings the device streams between panel updates.
  Stream<Object?>? _streamedChange() {
    final context = model.elementContext(item);
    for (final element in definition.elements) {
      final stream = element is RemoteInfo<Object>
          ? element.watch?.call(context)
          : null;
      if (stream != null) {
        return stream;
      }
    }
    return null;
  }

  Widget _layout() {
    final layout = definition.layout;
    if (layout is ElementGridLayout) {
      return GridView.count(
        crossAxisCount: layout.columns,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: ElementGridLayout.aspectRatio,
        children: [for (final element in _elements) _view(element)],
      );
    }
    return Flex(
      direction: _axis,
      children: [
        for (final element in _elements)
          Expanded(flex: element.slots, child: _view(element)),
      ],
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
