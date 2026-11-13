import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_editor_actions.dart';
import '../../widgets/grid/grid_page_dots.dart';
import 'grid_editor_canvas.dart';
import 'editor_toolbar.dart';
import '../../rendering/grid_remote_canvas.dart';
import '../../widgets/grid/models/remote_preview_data.dart';

class GridEditorContent extends StatelessWidget {
  const GridEditorContent({
    super.key,
    required this.model,
    required this.dependencies,
    this.parent,
    this.group,
    required this.viewport,
    required this.horizontal,
  });
  final GridEditorViewModel model;
  final RemoteEditorHost dependencies;
  final GridEditorViewModel? parent;
  final GridItem? group;
  final GlobalKey viewport;
  final ScrollController horizontal;
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
        body: SafeArea(top: false, child: _body(context, actions, viewport)),
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
    title: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Flexible(
          child: Text(
            group == null ? model.device.name : 'Edit group',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (group == null) _connection(context),
      ],
    ),
    centerTitle: true,
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
  Widget _connection(BuildContext context) => ListenableBuilder(
    listenable: dependencies.live.sessionChanges,
    builder: (context, _) {
      final connected = !dependencies
          .preview(model.device, sample: false)
          .offline;
      final colors = Theme.of(context).colorScheme;
      return Tooltip(
        message: connected ? 'Connected' : 'Disconnected',
        child: Icon(
          Icons.circle,
          size: 9,
          color: connected ? colors.primary : colors.outline,
        ),
      );
    },
  );

  Widget _body(
    BuildContext context,
    GridEditorActions actions,
    GlobalKey viewport,
  ) => Column(
    children: [
      EditorToolbar(
        model: model,
        actions: actions,
        insideGroup: group != null,
        onGridSettings: () => _gridSettings(context, actions, viewport),
      ),
      if (model.error != null)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            model.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      Expanded(
        key: viewport,
        child: model.mode == EditorMode.view
            ? _preview()
            : _editing(context, actions),
      ),
      if (model.mode == EditorMode.edit && !model.isGroup) _pages(context),
    ],
  );

  Widget _pages(BuildContext context) {
    final starts = model.draft.pageStarts;
    return GridPageDots(
      count: starts.length,
      selected: starts.indexOf(model.pageStart),
      onSelected: (index) => _jumpTo(starts[index]),
      swipe: false,
      leading: IconButton(
        tooltip: 'Delete page',
        onPressed: model.saving || model.pageStart == 0
            ? null
            : () => _deletePage(context),
        icon: const Icon(Icons.delete_outline),
      ),
      trailing: IconButton.filledTonal(
        tooltip: 'Add page',
        onPressed: model.saving ? null : _addPage,
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deletePage(BuildContext context) async {
    final index = model.draft.pageIndexAt(model.pageStart);
    final count = model.draft.pageItems(index).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete page ${index + 1}?'),
        content: Text(
          count == 0
              ? 'This removes the empty page.'
              : 'This removes the page and its $count controls.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete page'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      model.deletePage();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && horizontal.hasClients) {
          _jumpTo(model.pageStart);
        }
      });
    }
  }

  void _addPage() {
    model.addPage();
    final start = model.draft.pageStarts.last;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (horizontal.hasClients) {
        _jumpTo(start);
      }
    });
  }

  void _jumpTo(int column) {
    model.selectPage(column);
    if (!horizontal.hasClients) {
      return;
    }
    final offset = model.draft.pageOffset(model.draft.pageIndexAt(column));
    horizontal.jumpTo(offset.clamp(0.0, horizontal.position.maxScrollExtent));
  }

  Widget _preview() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
    child: GridRemoteCanvas(
      remote: dependencies.preview(model.device, sample: true),
      layout: model.draft,
      columns: model.columns,
      rows: group?.h,
      fitToScreen: true,
      interactive: false,
      initialPage: model.pageStart,
      onPageChanged: model.selectPage,
      previewData: RemotePreviewData.example,
    ),
  );

  Future<void> _gridSettings(
    BuildContext context,
    GridEditorActions actions,
    GlobalKey viewport,
  ) async {
    final renderBox = viewport.currentContext?.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) {
      return;
    }
    final size = renderBox.size;
    final width = size.width - 24;
    await actions.gridSettings(
      context,
      SquareGridMetrics(width: width, height: size.height - 28),
    );
    if (!context.mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && horizontal.hasClients) {
        _jumpTo(model.pageStart);
      }
    });
  }

  Widget _editing(BuildContext context, GridEditorActions actions) {
    final canvas = SingleChildScrollView(
      key: const PageStorageKey('remote-editor-canvas'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      child: GridEditorCanvas(
        model: model,
        dependencies: dependencies,
        onEdit: (item) => actions.edit(context, item),
        onAdd: (slot) => actions.library(context, at: slot),
      ),
    );
    final behavior = ScrollConfiguration.of(context);
    return SizedBox(
      width: double.infinity,
      child: ScrollConfiguration(
        behavior: behavior.copyWith(dragDevices: const {}),
        child: SingleChildScrollView(
          controller: horizontal,
          scrollDirection: Axis.horizontal,
          child: ScrollConfiguration(behavior: behavior, child: canvas),
        ),
      ),
    );
  }
}
