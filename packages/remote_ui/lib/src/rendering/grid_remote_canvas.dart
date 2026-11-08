import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../widgets/grid/grid_surface.dart';
import '../widgets/grid/fitted_grid_surface.dart';
import '../widgets/grid/models/remote_preview_data.dart';
import 'viewmodels/grid_remote_viewmodel.dart';
import 'grid_remote_item.dart';

class GridRemoteCanvas extends StatelessWidget {
  const GridRemoteCanvas({
    super.key,
    required this.remote,
    required this.layout,
    this.columns = 4,
    this.fitToScreen = false,
    this.previewData,
    this.rows,
  });
  final RemotePanel remote;
  final GridLayout layout;
  final int columns;
  final bool fitToScreen;
  final RemotePreviewData? previewData;
  final int? rows;
  @override
  Widget build(BuildContext context) {
    final model = GridRemoteViewModel(remote, previewData: previewData);
    Widget item(GridItem item) => GridRemoteItem(item: item, model: model);
    if (fitToScreen) {
      return FittedGridSurface(
        layout: layout,
        columns: columns,
        rows: rows,
        itemBuilder: item,
      );
    }
    return GridSurface(
      layout: layout,
      columns: columns,
      rows: rows,
      itemBuilder: item,
    );
  }
}
