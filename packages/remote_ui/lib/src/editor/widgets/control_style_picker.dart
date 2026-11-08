import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

class ControlStylePicker extends StatelessWidget {
  const ControlStylePicker({
    super.key,
    required this.kind,
    required this.onChanged,
    required this.columns,
    required this.capabilities,
  });
  final GridWidgetKind kind;
  final int columns;
  final Set<RemoteCapability> capabilities;
  final ValueChanged<GridWidgetKind> onChanged;
  @override
  Widget build(BuildContext context) {
    if (WidgetCatalog.definition(kind).category == RemoteItemCategory.groups) {
      return const SizedBox.shrink();
    }
    final choices = WidgetCatalog.variations(kind)
        .where(
          (item) =>
              (item.kind == kind || isCatalogCompatible(item, capabilities)) &&
              item.minimumWidth <= columns,
        )
        .toList();
    if (choices.length < 2) {
      return const SizedBox.shrink();
    }
    return DropdownButtonFormField<GridWidgetKind>(
      initialValue: choices.any((item) => item.kind == kind) ? kind : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Style'),
      items: choices
          .map(
            (item) => DropdownMenuItem(
              value: item.kind,
              child: Text(item.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
