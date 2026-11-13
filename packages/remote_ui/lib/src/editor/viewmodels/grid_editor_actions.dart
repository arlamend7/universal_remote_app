import '../grid_editor_page.dart';
import '../modals/grid_settings_sheet.dart';

import 'package:flutter/material.dart';
import 'package:remote_ui/src/widgets/sheets/show_app_sheet.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../../catalog/widget_library_sheet.dart';
import '../modals/widget_settings_sheet.dart';

final class GridEditorActions {
  GridEditorActions(this.dependencies, this.model, {this.parent, this.group});
  final RemoteEditorHost dependencies;
  final GridEditorViewModel model;
  final GridEditorViewModel? parent;
  final GridItem? group;

  /// Highlights [item] while its Edit Control sheet is open. However the
  /// sheet closes (Done, back, a swipe or a tap outside), the highlight clears.
  Future<void> edit(BuildContext context, GridItem item) async {
    model.select(item.id);
    try {
      await showAppModal<void>(
        context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (_) => WidgetSettingsSheet(
          item: item,
          model: model,
          dependencies: dependencies,
          onEditGroup: () => editGroup(context, item),
        ),
      );
    } finally {
      model.select(null);
    }
  }

  Future<void> editGroup(BuildContext context, GridItem item) {
    final group = model.selection ?? item;
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => GridEditorPage(
          dependencies: dependencies,
          device: model.device,
          parent: model,
          group: group,
        ),
      ),
    );
  }

  Future<void> library(BuildContext context, {({int x, int y})? at}) async {
    final definitionId = await showAppModal<String>(
      context,
      builder: (_) => WidgetLibrarySheet(
        model: model,
        dependencies: dependencies,
        insideGroup: group != null,
      ),
    );
    if (definitionId == null || !context.mounted) {
      return;
    }
    final item = model.add(definitionId, at: at);
    if (item == null) {
      return;
    }
    if (item.isGroup) {
      await editGroup(context, item);
    }
  }

  Future<void> save(BuildContext context) async {
    if (group != null && parent != null) {
      parent!.update(group!.copy(children: model.draft.items));
      if (parent!.error == null && context.mounted) {
        Navigator.pop(context);
      }
      return;
    }
    if (await model.save() && context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> gridSettings(
    BuildContext context,
    SquareGridMetrics metrics,
  ) async {
    final page = model.draft.pageIndexAt(model.pageStart);
    final result =
        await showAppModal<({int columns, int rows, double cellSize})>(
          context,
          builder: (_) => GridSettingsSheet(
            layout: model.draft.pageLayout(page),
            metrics: metrics,
            pageNumber: page + 1,
          ),
        );
    if (result != null &&
        context.mounted &&
        model.draft.pageIndexAt(model.pageStart) == page) {
      model.setDimensions(
        result.columns,
        result.rows,
        cellSize: result.cellSize,
      );
    }
  }

  Future<void> reset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group == null ? 'Reset layout?' : 'Clear group?'),
        content: const Text(
          'This changes your draft. You can undo it before saving.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      model.reset();
    }
  }
}
