import 'package:flutter/material.dart';
import 'package:remote_ui/src/widgets/sheets/show_app_sheet.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../../catalog/style_picker_sheet.dart';

/// Shows the current style and opens a preview list of the control's
/// alternative looks. Hidden when the control has none.
class ControlStylePicker extends StatelessWidget {
  const ControlStylePicker({
    super.key,
    required this.definitionId,
    required this.onChanged,
    required this.columns,
    required this.capabilities,
    required this.dependencies,
    required this.device,
  });
  final String definitionId;
  final int columns;
  final Set<RemoteCapability> capabilities;
  final RemoteEditorHost dependencies;
  final RemoteDevice device;
  final ValueChanged<String> onChanged;

  List<RemoteItemDefinition<Object>> get _choices =>
      RemoteItemRegistry.variations(definitionId)
          .where(
            (item) =>
                (item.id == definitionId ||
                    item.isCompatibleWith(capabilities)) &&
                item.minimumWidth <= columns,
          )
          .toList();

  @override
  Widget build(BuildContext context) {
    final choices = _choices;
    if (choices.length < 2) {
      return const SizedBox.shrink();
    }
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _choose(context, choices),
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Style'),
        child: Row(
          children: [
            Expanded(
              child: Text(
                RemoteItemRegistry.resolve(definitionId).name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Future<void> _choose(
    BuildContext context,
    List<RemoteItemDefinition<Object>> choices,
  ) async {
    final id = await showAppModal<String>(
      context,
      builder: (_) => StylePickerSheet(
        choices: choices,
        selectedId: definitionId,
        dependencies: dependencies,
        device: device,
      ),
    );
    if (id != null && id != definitionId) {
      onChanged(id);
    }
  }
}
