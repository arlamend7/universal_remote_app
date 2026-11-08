import 'package:remote_ui/src/ui_model.dart';
import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../viewmodels/grid_remote_viewmodel.dart';

class GridKeypadWidget extends StatelessWidget {
  const GridKeypadWidget({super.key, required this.model});
  final GridRemoteViewModel model;
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 3,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 1.1,
    children: [
      for (final index in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 0, 11]) _key(index),
    ],
  );
  Widget _key(int index) => TextButton(
    onPressed: model.ready && model.supports(RemoteCapability.pointer)
        ? () =>
              RemoteItemRegistry.resolve(GridWidgetKind.keypad)
                  .element(TvItems.specialKey)
                  .onPressed(
                    model,
                    index == 10
                        ? RemoteKey.dash
                        : index == 11
                        ? RemoteKey.enter
                        : RemoteKey.values[index],
                  )
        : null,
    child: Text(
      index == 10
          ? '−'
          : index == 11
          ? 'Enter'
          : '$index',
    ),
  );
}
