import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:remote_ui/src/ui_model.dart';

import 'dial_input.dart';
import 'info_display.dart';

class DialInputState extends State<DialInput> {
  double? _pending;
  Object? _owner;

  List<RemoteElement<Object>> get _elements => widget.item.definition.elements;
  RemoteInput<Object, double> get _input =>
      _elements.whereType<RemoteInput<Object, double>>().first;
  RemoteInfo<Object> get _reading =>
      _elements.whereType<RemoteInfo<Object>>().first;
  RemoteElementContext get _context => widget.model.elementContext(widget.item);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _dial(context, constraints.biggest),
  );

  Widget _dial(BuildContext context, Size size) {
    final reading = _input.current?.call(_context);
    final current = reading != null && reading.isFinite ? reading : null;
    final bounds = _input.bounds(_context);
    final span = bounds.maximum - bounds.minimum;
    if (!span.isFinite || span <= 0) {
      return const SizedBox.shrink();
    }
    final enabled =
        current != null &&
        widget.item.definition.isAvailableOn(widget.model.remote) &&
        widget.model.canBindInput(_input);
    final value = _pending ?? current;
    final configuredStep = bounds.step;
    final step =
        configuredStep != null && configuredStep.isFinite && configuredStep > 0
        ? configuredStep
        : 1.0;
    return Semantics(
      label: 'Dial',
      value: value?.round().toString() ?? 'Unavailable',
      increasedValue: enabled
          ? (value! + step)
                .clamp(bounds.minimum, bounds.maximum)
                .round()
                .toString()
          : null,
      decreasedValue: enabled
          ? (value! - step)
                .clamp(bounds.minimum, bounds.maximum)
                .round()
                .toString()
          : null,
      onIncrease: enabled ? () => _press(context, 0) : null,
      onDecrease: enabled ? () => _press(context, 1) : null,
      child: Listener(
        onPointerCancel: (_) => _discard(),
        child: GestureDetector(
          onPanStart: enabled
              ? (_) => _owner = widget.model.remote.connection.controller
              : null,
          onPanUpdate: enabled
              ? (details) => _preview(details.localPosition, size)
              : null,
          onPanEnd: enabled ? (_) => _commit() : null,
          onPanCancel: _discard,
          child: _face(
            context,
            size,
            ((_pending ?? current ?? bounds.minimum) - bounds.minimum) / span,
          ),
        ),
      ),
    );
  }

  Widget _face(BuildContext context, Size size, double progress) => Center(
    child: SizedBox.square(
      dimension: math.max(0, math.min(size.width, size.height) - 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress.isFinite ? progress.clamp(0, 1) : 0,
              strokeWidth: 5,
              backgroundColor: Theme.of(context).dividerColor,
            ),
          ),
          InfoDisplay(info: _reading, item: widget.item, model: widget.model),
        ],
      ),
    ),
  );

  void _press(BuildContext context, int index) {
    final action = _elements.whereType<RemoteAction<Object>>().elementAtOrNull(
      index,
    );
    if (action != null) {
      widget.model.press(action, widget.item, context);
    }
  }

  void _commit() {
    final value = _pending;
    final sameSession = identical(
      _owner,
      widget.model.remote.connection.controller,
    );
    _discard();
    if (value == null || !sameSession) {
      return;
    }
    RemoteFeedback.commit();
    unawaited(widget.model.commitInput(_input, value));
  }

  void _discard() {
    setState(() {
      _pending = null;
      _owner = null;
    });
  }

  void _preview(Offset point, Size size) {
    if (!identical(_owner, widget.model.remote.connection.controller)) {
      return;
    }
    final bounds = _input.bounds(_context);
    final angle =
        (math.atan2(point.dy - size.height / 2, point.dx - size.width / 2) +
            math.pi / 2 +
            math.pi * 2) %
        (math.pi * 2);
    final span = bounds.maximum - bounds.minimum;
    final raw = angle / (math.pi * 2) * span;
    final step = bounds.step;
    final steps = step != null && step > 0 ? raw / step : double.nan;
    final offset = step != null && step.isFinite && steps.isFinite
        ? steps.round() * step
        : raw;
    final value = (bounds.minimum + offset).clamp(
      bounds.minimum,
      bounds.maximum,
    );
    setState(() => _pending = value);
    widget.model.previewInput(_input, value);
  }
}
