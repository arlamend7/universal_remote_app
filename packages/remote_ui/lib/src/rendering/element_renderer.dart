import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'primitives/collection_view.dart';
import 'primitives/dial_input.dart';
import 'primitives/element_strip.dart';
import 'primitives/navigation_surface.dart';
import 'primitives/group_surface.dart';
import 'primitives/touch_surface.dart';
import 'primitives/unavailable_notice.dart';
import 'viewmodels/grid_remote_viewmodel.dart';

/// Draws an item by its registered layout. Which primitive appears, and every
/// choice inside it, comes from the definition; no item id is inspected here.
class ElementRenderer extends StatelessWidget
    implements RemoteLayoutVisitor<Widget> {
  const ElementRenderer({super.key, required this.item, required this.model});
  final GridItem item;
  final GridRemoteViewModel model;

  @override
  Widget build(BuildContext context) => item.definition.layout.accept(this);

  Widget _strip() =>
      ElementStrip(definition: item.definition, item: item, model: model);

  @override
  Widget visitLinear(LinearLayout layout) => _strip();

  @override
  Widget visitElementGrid(ElementGridLayout layout) => _strip();

  @override
  Widget visitDial(DialLayout layout) => DialInput(item: item, model: model);

  @override
  Widget visitCollection(CollectionLayout layout) =>
      CollectionView(definition: item.definition, item: item, model: model);

  @override
  Widget visitDirectionPad(DirectionPadLayout layout) =>
      NavigationSurface(item: item, model: model);

  @override
  Widget visitEmpty(EmptyLayout layout) => const SizedBox.shrink();

  @override
  Widget visitGroup(GroupLayout layout) =>
      GroupSurface(item: item, model: model);

  @override
  Widget visitTouchSurface(TouchSurfaceLayout layout) =>
      TouchSurface(item: item, model: model);

  @override
  Widget visitUnavailable(UnavailableLayout layout) => UnavailableNotice(
    title: item.definition.name,
    reason: 'This control is unavailable for this device.',
  );
}
