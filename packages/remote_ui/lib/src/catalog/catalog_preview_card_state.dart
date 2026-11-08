import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../editor/widgets/grid_item_preview.dart';
import 'catalog_preview_card.dart';

/// The hovered name is highlighted in place; there is no separate tooltip box.
class CatalogPreviewCardState extends State<CatalogPreviewCard> {
  bool _hovered = false;

  RemoteItemDefinition<Object> get _definition => widget.definition;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Add ${_definition.name}',
    child: Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: widget.onAdd,
        onHover: (value) => setState(() => _hovered = value),
        child: _content(context),
      ),
    ),
  );

  Widget _content(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [
        Expanded(child: _preview()),
        const SizedBox(height: 6),
        _name(Theme.of(context).colorScheme),
      ],
    ),
  );

  Widget _name(ColorScheme colors) => AnimatedContainer(
    duration: const Duration(milliseconds: 120),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: _hovered ? colors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      _definition.name,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: _hovered ? colors.onPrimaryContainer : null),
    ),
  );

  Widget _preview() => FittedBox(
    fit: BoxFit.contain,
    child: SizedBox(
      width: _definition.width * 80.0,
      height: _definition.height * 80.0,
      child: ExcludeSemantics(
        child: GridItemPreview(
          item: GridItem(
            id: _definition.id,
            definitionId: _definition.id,
            x: 0,
            y: 0,
            w: _definition.width,
            h: _definition.height,
          ),
          dependencies: widget.dependencies,
          device: widget.device,
          sample: true,
        ),
      ),
    ),
  );
}
