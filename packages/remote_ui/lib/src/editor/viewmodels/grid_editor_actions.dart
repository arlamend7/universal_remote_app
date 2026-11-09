import '../grid_editor_page.dart';

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
  Future<void> edit(BuildContext context, GridItem item) async {
    model.select(item.id);
    await showAppModal<void>(
      context,
      builder: (_) => WidgetSettingsSheet(
        item: item,
        model: model,
        dependencies: dependencies,
        onEditGroup: () => editGroup(context, item),
      ),
    );
  }

  Future<void> editGroup(BuildContext context, GridItem item) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => GridEditorPage(
            dependencies: dependencies,
            device: model.device,
            parent: model,
            group: model.selection ?? item,
          ),
        ),
      );
  Future<void> library(BuildContext context) async {
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
    final item = model.add(definitionId);
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

  void option(String action) {
    if (action == 'rows') {
      model.extend();
      return;
    }
    if (action == 'reset') {
      model.reset();
    }
  }
}
