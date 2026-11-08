import 'package:flutter/material.dart';

import 'package:remote_ui/remote_ui.dart';

import '../viewmodels/remote_viewmodel.dart';
import '../widgets/remote_header.dart';

class RemoteViewport extends StatelessWidget {
  const RemoteViewport({super.key, required this.model});
  final RemoteViewModel model;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          spacing: 8,
          children: [
            RemoteHeader(model: model),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor,
            ),
            Expanded(child: _controls()),
          ],
        ),
      ),
    ),
  );
  Widget _controls() {
    final grid = model.grid ?? defaultRemoteGrid();
    if (grid.items.isEmpty) {
      return const Center(
        child: Text(
          'Make this remote yours. Add controls from Customize remote.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return GridRemoteCanvas(remote: model, layout: grid, fitToScreen: true);
  }
}
