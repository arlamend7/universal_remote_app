import 'package:flutter/material.dart';
import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_editor_actions.dart';
import '../../widgets/tabs/remote_tabs.dart';

class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    super.key,
    required this.model,
    required this.actions,
    required this.insideGroup,
    required this.onGridSettings,
  });

  final GridEditorViewModel model;
  final GridEditorActions actions;
  final bool insideGroup;
  final VoidCallback onGridSettings;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RemoteTabs(
          tabs: const [
            (
              value: EditorMode.edit,
              label: 'Edit Layout',
              icon: Icons.edit_outlined,
            ),
            (
              value: EditorMode.view,
              label: 'View Mode',
              icon: Icons.visibility_outlined,
            ),
          ],
          selected: model.mode,
          onChanged: model.setMode,
        ),
        if (model.mode == EditorMode.edit) _tools(context),
      ],
    ),
  );

  Widget _tools(BuildContext context) => OverflowBar(
    alignment: MainAxisAlignment.spaceBetween,
    overflowAlignment: OverflowBarAlignment.center,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!insideGroup)
            _tool(Icons.grid_view, 'Grid Settings', onGridSettings),
          _tool(Icons.undo, 'Undo', model.canUndo ? model.undo : null),
          _tool(Icons.redo, 'Redo', model.canRedo ? model.redo : null),
        ],
      ),

      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            key: const ValueKey('add-control'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              shape: const StadiumBorder(),
            ),
            onPressed: model.saving ? null : () => actions.library(context),
            icon: const Icon(Icons.add, size: 17),
            label: const Text('Add'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: model.saving ? null : () => actions.reset(context),
            child: const Text('Reset'),
          ),
        ],
      ),
    ],
  );

  Widget _tool(IconData icon, String label, VoidCallback? action) => IconButton(
    tooltip: label,
    onPressed: model.saving ? null : action,
    icon: Icon(icon),
  );
}
