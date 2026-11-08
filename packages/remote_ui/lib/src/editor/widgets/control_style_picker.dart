import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

class ControlStylePicker extends StatelessWidget {
  const ControlStylePicker({
    super.key,
    required this.definitionId,
    required this.onChanged,
    required this.columns,
    required this.capabilities,
  });
  final String definitionId;
  final int columns;
  final Set<RemoteCapability> capabilities;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    if (RemoteItemRegistry.resolve(definitionId).category ==
        RemoteItemCategory.groups) {
      return const SizedBox.shrink();
    }
    final choices = RemoteItemRegistry.variations(definitionId)
        .where(
          (item) =>
              (item.id == definitionId ||
                  item.isCompatibleWith(capabilities)) &&
              item.minimumWidth <= columns,
        )
        .toList();
    if (choices.length < 2) {
      return const SizedBox.shrink();
    }
    return DropdownButtonFormField<String>(
      initialValue: choices.any((item) => item.id == definitionId)
          ? definitionId
          : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Style'),
      items: choices
          .map(
            (item) => DropdownMenuItem(
              value: item.id,
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
