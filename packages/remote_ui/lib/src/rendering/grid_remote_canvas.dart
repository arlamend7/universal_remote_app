import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../widgets/grid/grid_surface.dart';
import '../widgets/grid/remote_grid_pages.dart';
import '../widgets/grid/fitted_grid_surface.dart';
import '../widgets/grid/models/remote_preview_data.dart';
import 'viewmodels/grid_remote_viewmodel.dart';
import 'grid_remote_item.dart';

class GridRemoteCanvas extends StatelessWidget {
  const GridRemoteCanvas({
    super.key,
    required this.remote,
    required this.layout,
    this.columns,
    this.fitToScreen = false,
    this.interactive = true,
    this.previewData,
    this.rows,
    this.initialPage = 0,
    this.onPageChanged,
  });
  final RemotePanel remote;
  final GridLayout layout;
  final int? columns;
  final bool fitToScreen, interactive;
  final RemotePreviewData? previewData;
  final int? rows;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;
  @override
  Widget build(BuildContext context) {
    final model = GridRemoteViewModel(remote, previewData: previewData);
    Widget item(GridItem item) {
      final control = GridRemoteItem(item: item, model: model);
      if (!interactive) {
        return ExcludeFocus(child: IgnorePointer(child: control));
      }
      return control;
    }

    final gridColumns = columns ?? layout.columns;
    if (rows == null && fitToScreen) {
      return RemoteGridPages(
        layout: layout,
        itemBuilder: item,
        swipeOnCanvas: !interactive,
        ownsDragGesture: interactive ? _ownsDragGesture : null,
        initialPage: initialPage,
        onPageChanged: onPageChanged,
      );
    }
    if (fitToScreen) {
      return FittedGridSurface(
        layout: layout,
        columns: gridColumns,
        rows: rows,
        itemBuilder: item,
      );
    }
    return GridSurface(
      layout: layout,
      columns: gridColumns,
      rows: rows,
      itemBuilder: item,
    );
  }

  bool _ownsDragGesture(GridItem item) =>
      item.definition.layout is TouchSurfaceLayout ||
      item.definition.layout is DialLayout ||
      item.definition.layout is CollectionLayout ||
      item.definition.elements.any(
        (element) => element is RemoteInput<Object, double>,
      ) ||
      item.children.any(_ownsDragGesture);
}
