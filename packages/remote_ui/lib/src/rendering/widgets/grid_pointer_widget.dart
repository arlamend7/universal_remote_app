import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'package:remote_core/remote_core.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import 'grid_unavailable.dart';

class GridPointerWidget extends StatelessWidget {
  const GridPointerWidget({
    super.key,
    required this.model,
    this.configuration = const TouchpadConfiguration(),
  });
  final GridRemoteViewModel model;
  final TouchpadConfiguration configuration;
  @override
  Widget build(BuildContext context) {
    if (!model.supports(RemoteCapability.pointer)) {
      return const GridUnavailable(
        title: 'Touchpad unavailable',
        reason: 'A permitted pointer socket is required. Check this TV’s navigation compatibility settings.',
      );
    }
    return Semantics(
      label: 'TV touchpad. Tap to select; drag to move; use two fingers to scroll.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: model.ready
            ? () {
                RemoteFeedback.commit();
                RemoteItemRegistry.resolve(GridWidgetKind.touchpad)
                    .element(TvItems.pointerClick)
                    .onPressed(model, null);
              }
            : null,
        onScaleUpdate: model.ready ? _move : null,
        child: const Center(child: Icon(Icons.touch_app_outlined)),
      ),
    );
  }

  void _move(ScaleUpdateDetails details) {
    final scroll = details.pointerCount > 1;
    if (scroll && !configuration.scroll) {
      return;
    }
    final delta = details.focalPointDelta * configuration.sensitivity;
    RemoteItemRegistry.resolve(GridWidgetKind.touchpad)
        .element(TvItems.touchpad)
        .commit(model, (x: delta.dx, y: delta.dy, scroll: scroll));
  }
}
