import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import 'unavailable_notice.dart';

typedef _Motion = ({double x, double y, bool scroll});

/// A pointer surface: dragging feeds the definition's motion input and a tap
/// presses its click action.
class TouchSurface extends StatelessWidget {
  const TouchSurface({super.key, required this.item, required this.model});
  final GridItem item;
  final GridRemoteViewModel model;

  List<RemoteElement<Object>> get _elements => item.definition.elements;

  RemoteInput<TvRemoteDevice, _Motion> get _motion =>
      _elements.whereType<RemoteInput<Object, _Motion>>().first
          as RemoteInput<TvRemoteDevice, _Motion>;

  RemoteAction<Object> get _click =>
      _elements.whereType<RemoteAction<Object>>().first;

  RemoteItemDefinition<Object> get _definition => item.definition;

  @override
  Widget build(BuildContext context) {
    if (!item.definition.isSupportedBy(model.remote)) {
      return const UnavailableNotice(
        title: 'Touchpad unavailable',
        reason: 'A permitted pointer socket is required. Check this TV’s navigation compatibility settings.',
      );
    }
    return Semantics(
      label: 'TV touchpad. Tap to select; drag to move; use two fingers to scroll.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: model.ready ? () => _tap(context) : null,
        onScaleUpdate: model.ready ? _move : null,
        child: const Center(child: Icon(Icons.touch_app_outlined)),
      ),
    );
  }

  void _tap(BuildContext context) {
    RemoteFeedback.commit();
    model.press(_click, item, context);
  }

  void _move(ScaleUpdateDetails details) {
    final scroll = details.pointerCount > 1;
    if (scroll && !_definition.setting('twoFingerScroll').isOn(item.config)) {
      return;
    }
    final delta =
        details.focalPointDelta *
        _definition.setting('sensitivity').number(item.config);
    _motion.commit(model, (x: delta.dx, y: delta.dy, scroll: scroll));
  }
}
