import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_editor_actions.dart';

/// One row of mode and edit actions, with its hint underneath.
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    super.key,
    required this.model,
    required this.actions,
    required this.insideGroup,
  });
  final GridEditorViewModel model;
  final GridEditorActions actions;
  final bool insideGroup;

  bool get _editing => model.mode == EditorMode.edit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _actions(context, compact: constraints.maxWidth < 400),
          const SizedBox(height: 6),
          _hint(context),
        ],
      ),
    ),
  );

  Widget _actions(BuildContext context, {required bool compact}) => Row(
    children: [
      _modes(),
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                if (_editing) ..._editActions(context, compact: compact),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _modes() => SegmentedButton<EditorMode>(
    showSelectedIcon: false,
    segments: const [
      ButtonSegment(
        value: EditorMode.view,
        icon: Icon(Icons.visibility_outlined),
        tooltip: 'View',
      ),
      ButtonSegment(
        value: EditorMode.edit,
        icon: Icon(Icons.edit_outlined),
        tooltip: 'Edit',
      ),
    ],
    selected: {model.mode},
    onSelectionChanged: (values) => model.setMode(values.single),
  );

  List<Widget> _editActions(BuildContext context, {required bool compact}) => [
    _add(context, compact: compact),
    IconButton(
      tooltip: 'Undo',
      visualDensity: VisualDensity.compact,
      onPressed: model.canUndo && !model.saving ? model.undo : null,
      icon: const Icon(Icons.undo),
    ),
    IconButton(
      tooltip: 'Redo',
      visualDensity: VisualDensity.compact,
      onPressed: model.canRedo && !model.saving ? model.redo : null,
      icon: const Icon(Icons.redo),
    ),
    _options(),
  ];

  Widget _add(BuildContext context, {required bool compact}) {
    final onPressed = model.saving ? null : () => actions.library(context);
    if (compact) {
      return IconButton.filledTonal(
        key: const ValueKey('add-control'),
        tooltip: 'Add control',
        onPressed: onPressed,
        icon: const Icon(Icons.add),
      );
    }
    return FilledButton.tonalIcon(
      key: const ValueKey('add-control'),
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Add control'),
    );
  }

  Widget _hint(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        _editing
            ? 'Tap to edit. Drag or hold to move. Pull a corner to resize.'
            : 'Sample data · preview only',
        maxLines: 1,
        softWrap: false,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  );

  Widget _options() => PopupMenuButton<String>(
    tooltip: 'Layout options',
    enabled: !model.saving,
    onSelected: actions.option,
    itemBuilder: (_) => [
      if (!insideGroup)
        const PopupMenuItem(value: 'rows', child: Text('More space')),
      PopupMenuItem(
        value: 'reset',
        child: Text(insideGroup ? 'Clear group' : 'Start over'),
      ),
    ],
  );
}
