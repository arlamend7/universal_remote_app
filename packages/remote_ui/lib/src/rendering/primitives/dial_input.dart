import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import 'info_display.dart';

/// A numeric [RemoteInput] turned by dragging around a circle, with the
/// registered reading in the middle and the registered up/down actions
/// exposed to assistive technology.
class DialInput extends StatelessWidget {
  const DialInput({super.key, required this.item, required this.model});
  final GridItem item;
  final GridRemoteViewModel model;

  List<RemoteElement<Object>> get _elements => item.definition.elements;

  RemoteInput<TvRemoteDevice, double> get _input =>
      _elements.whereType<RemoteInput<Object, double>>().first
          as RemoteInput<TvRemoteDevice, double>;

  RemoteInfo<Object> get _reading =>
      _elements.whereType<RemoteInfo<Object>>().first;

  RemoteAction<Object> _action(int index) =>
      _elements.whereType<RemoteAction<Object>>().elementAt(index);

  RemoteElementContext get _context => model.elementContext(item);

  double? get _current => _input.current!(_context);
  bool get _enabled =>
      item.definition.isAvailableOn(model.remote) && _current != null;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Semantics(
      label: 'Dial',
      value: _current?.round().toString() ?? 'Unavailable',
      onIncrease: _enabled ? () => _press(context, 0) : null,
      onDecrease: _enabled ? () => _press(context, 1) : null,
      child: GestureDetector(
        onPanUpdate: _enabled
            ? (details) => _preview(details.localPosition, constraints.biggest)
            : null,
        onPanEnd: _enabled ? (_) => _commit() : null,
        child: Center(
          child: SizedBox.square(
            dimension:
                math.min(constraints.maxWidth, constraints.maxHeight) - 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: (_current ?? 0) / _input.maximum,
                    strokeWidth: 5,
                    backgroundColor: Theme.of(context).dividerColor,
                  ),
                ),
                InfoDisplay(info: _reading, item: item, model: model),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  void _press(BuildContext context, int index) =>
      model.press(_action(index), item, context);

  void _commit() {
    RemoteFeedback.commit();
    _input.commit(model, _current ?? 0);
  }

  void _preview(Offset point, Size size) {
    final angle =
        (math.atan2(point.dy - size.height / 2, point.dx - size.width / 2) +
            math.pi / 2 +
            math.pi * 2) %
        (math.pi * 2);
    _input.preview?.call(model, angle / (math.pi * 2) * _input.maximum);
  }
}
