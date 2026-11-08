import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_editor_actions.dart';
import 'grid_editor_canvas.dart';
import 'editor_toolbar.dart';
import '../../rendering/widgets/grid_remote_canvas.dart';
import '../../widgets/grid/models/remote_preview_data.dart';

class GridEditorContent extends StatelessWidget {
  const GridEditorContent({
    super.key,
    required this.model,
    required this.dependencies,
    this.parent,
    this.group,
  });
  final GridEditorViewModel model;
  final RemoteEditorHost dependencies;
  final GridEditorViewModel? parent;
  final GridItem? group;
  @override
  Widget build(BuildContext context) {
    final actions = GridEditorActions(
      dependencies,
      model,
      parent: parent,
      group: group,
    );
    return PopScope(
      canPop: !model.saving,
      child: Scaffold(
        appBar: _header(context, actions),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _body(context, actions),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _header(
    BuildContext context,
    GridEditorActions actions,
  ) => AppBar(
    leading: IconButton(
      tooltip: 'Back to remote',
      onPressed: model.saving ? null : () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back),
    ),
    title: Text(
      group == null ? model.device.name : 'Edit group',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    actions: [
      IconButton.filled(
        tooltip: group == null ? 'Done' : 'Apply group',
        onPressed: model.saving ? null : () => actions.save(context),
        icon: model.saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
      ),
      const SizedBox(width: 12),
    ],
  );
  Widget _body(BuildContext context, GridEditorActions actions) => Column(
    children: [
      EditorToolbar(model: model, actions: actions, insideGroup: group != null),
      if (model.error != null)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            model.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      Expanded(
        child: model.mode == EditorMode.view
            ? _preview()
            : _editing(context, actions),
      ),
    ],
  );
  Widget _preview() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: ExcludeFocus(
      child: IgnorePointer(
        child: GridRemoteCanvas(
          remote: dependencies.preview(model.device, sample: true),
          layout: model.draft,
          columns: model.columns,
          rows: group?.h,
          fitToScreen: true,
          previewData: RemotePreviewData.example,
        ),
      ),
    ),
  );
  Widget _editing(BuildContext context, GridEditorActions actions) =>
      SingleChildScrollView(
        key: const PageStorageKey('remote-editor-canvas'),
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: GridEditorCanvas(
          model: model,
          dependencies: dependencies,
          onEdit: (item) => actions.edit(context, item),
        ),
      );
}
