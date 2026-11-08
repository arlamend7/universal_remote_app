import '../../widgets/grid/models/remote_preview_data.dart';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../../rendering/widgets/grid_remote_widget.dart';
import '../../rendering/viewmodels/grid_remote_viewmodel.dart';

/// Exactly the runtime renderer and constraints. Editing never sends a command.
class GridItemPreview extends StatelessWidget {
  const GridItemPreview({
    super.key,
    required this.item,
    this.dependencies,
    this.device,
    this.sample = false,
  });
  final GridItem item;
  final RemoteEditorHost? dependencies;
  final RemoteDevice? device;
  final bool sample;
  @override
  Widget build(BuildContext context) {
    if (dependencies == null || device == null) {
      return const Center(child: Icon(Icons.widgets_outlined));
    }
    final remote = dependencies!.preview(device!, sample: sample);
    final model = GridRemoteViewModel(
      remote,
      previewData: sample ? RemotePreviewData.example : null,
    );
    return ExcludeSemantics(
      child: ExcludeFocus(
        child: IgnorePointer(
          child: ListenableBuilder(
            listenable: remote.changes,
            builder: (_, _) => GridRemoteWidget(item: item, model: model),
          ),
        ),
      ),
    );
  }
}
