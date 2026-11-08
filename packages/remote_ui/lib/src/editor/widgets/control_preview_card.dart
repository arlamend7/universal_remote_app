import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'package:remote_core/remote_core.dart';

import 'grid_item_preview.dart';

class ControlPreviewCard extends StatelessWidget {
  const ControlPreviewCard({
    super.key,
    required this.item,
    required this.dependencies,
    required this.device,
    this.onAdd,
  });
  final GridItem item;
  final RemoteEditorHost dependencies;
  final RemoteDevice device;
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [_preview(), _information(context)]),
    ),
  );
  Widget _preview() => SizedBox(
    height: 160,
    width: double.infinity,
    child: FittedBox(
      child: SizedBox(
        width: item.w * 80.0,
        height: item.h * 80.0,
        child: UniversalRemoteItem.control(
          quarterTurns: item.quarterTurns,
          style: item.style,
          child: GridItemPreview(
            item: item.unrotated,
            dependencies: dependencies,
            device: device,
          ),
        ),
      ),
    ),
  );
  Widget _information(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(WidgetCatalog.definition(item.kind).name),
    subtitle: Text('Preview · ${item.w} × ${item.h}'),
    trailing: onAdd == null
        ? null
        : IconButton(
            tooltip: 'Add ${WidgetCatalog.definition(item.kind).name}',
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
          ),
  );
}
