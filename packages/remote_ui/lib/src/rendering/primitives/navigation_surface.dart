import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import 'element_view.dart';
import 'unavailable_notice.dart';

/// Lays a definition's elements around a ring: the first four go top, right,
/// bottom and left, a fifth goes in the centre; any further elements (Home, Back) form a shortcut
/// row when the item enables shortcuts.
class NavigationSurface extends StatelessWidget {
  const NavigationSurface({super.key, required this.item, required this.model});
  final GridItem item;
  final GridRemoteViewModel model;

  static const _key = DirectionPadLayout.shortcutRow;

  RemoteItemDefinition<Object> get _definition => item.definition;

  List<RemoteElement<Object>> get _elements => _definition.elements;

  PadShape get _shape => (_definition.layout as DirectionPadLayout).shape;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final shortcuts = item.config['shortcuts'] == 'true';
      final side = math.min(
        constraints.maxWidth,
        constraints.maxHeight - (shortcuts ? _key : 0),
      );
      if (side < DirectionPadLayout.minimumSide) {
        return const UnavailableNotice(
          title: 'Enlarge navigation',
          reason: 'Use at least three columns on this screen to preserve accessible direction targets.',
        );
      }
      return Column(
        children: [
          Expanded(child: Center(child: _ring(context, side))),
          if (shortcuts) _shortcuts(),
        ],
      );
    },
  );

  Widget _shortcuts() => SizedBox(
    height: _key,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [for (final element in _elements.skip(5)) _view(element)],
    ),
  );

  Widget _ring(BuildContext context, double side) => Container(
    width: side,
    height: side,
    decoration: BoxDecoration(
      shape: _shape == PadShape.square ? BoxShape.rectangle : BoxShape.circle,
      // With the item's background on, the card fill covers everything and
      // the ring adds no second shape on top.
      color: item.style.showBackground
          ? null
          : StyledItem.cardColor(Theme.of(context).colorScheme),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        _place(Alignment.topCenter, _elements[0]),
        _place(Alignment.centerRight, _elements[1]),
        _place(Alignment.bottomCenter, _elements[2]),
        _place(Alignment.centerLeft, _elements[3]),
        if (_elements.length > 4) _place(Alignment.center, _elements[4]),
      ],
    ),
  );

  Widget _place(Alignment alignment, RemoteElement<Object> element) => Align(
    alignment: alignment,
    child: SizedBox.square(
      dimension: DirectionPadLayout.directionTarget,
      child: _view(element),
    ),
  );

  Widget _view(RemoteElement<Object> element) => ElementView(
    definition: _definition,
    element: element,
    item: item,
    model: model,
    axis: Axis.horizontal,
  );
}
