import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'device_tile.dart';
import 'device_swipe_actions.dart';
import 'swipe_device_tile.dart';

class SwipeDeviceTileState extends State<SwipeDeviceTile> {
  static const _revealWidth = 144.0;
  double _offset = 0;
  bool _dragging = false;

  double get _direction =>
      Directionality.of(context) == TextDirection.ltr ? -1 : 1;

  @override
  Widget build(BuildContext context) => Semantics(
    customSemanticsActions: {
      const CustomSemanticsAction(label: 'Edit device'): _edit,
      const CustomSemanticsAction(label: 'Delete device'): _delete,
    },
    child: GestureDetector(
      onHorizontalDragStart: (_) => setState(() => _dragging = true),
      onHorizontalDragUpdate: _drag,
      onHorizontalDragEnd: _endDrag,
      onHorizontalDragCancel: () => _settle(false),
      child: _row(),
    ),
  );

  Widget _row() => ClipRect(
    child: Stack(
      children: [
        Positioned.fill(child: _actions()),
        TweenAnimationBuilder<double>(
          tween: Tween(end: _offset),
          duration: _dragging
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          builder: (_, offset, child) => Transform.translate(
            offset: Offset(offset * _direction, 0),
            child: child,
          ),
          child: DeviceTile(
            model: widget.model,
            device: widget.device,
            onTap: _tap,
            onLongPress: () => _settle(_offset == 0),
          ),
        ),
      ],
    ),
  );

  Widget _actions() => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: ExcludeFocus(
      excluding: _offset < _revealWidth,
      child: IgnorePointer(
        ignoring: _offset < _revealWidth,
        child: ExcludeSemantics(
          excluding: _offset < _revealWidth,
          child: DeviceSwipeActions(
            width: _revealWidth,
            onEdit: _edit,
            onDelete: _delete,
          ),
        ),
      ),
    ),
  );

  void _drag(DragUpdateDetails details) => setState(() {
    _offset = (_offset + details.delta.dx * _direction).clamp(0, _revealWidth);
  });

  void _endDrag(DragEndDetails details) {
    final velocity = (details.primaryVelocity ?? 0) * _direction;
    _settle(velocity.abs() > 250 ? velocity > 0 : _offset >= _revealWidth / 2);
  }

  void _settle(bool open) => setState(() {
    _dragging = false;
    _offset = open ? _revealWidth : 0;
  });

  void _tap() {
    if (_offset > 0) {
      _settle(false);
      return;
    }
    widget.model.onConnect(widget.device);
  }

  void _edit() {
    _settle(false);
    widget.model.edit(context, widget.device);
  }

  void _delete() {
    _settle(false);
    widget.model.forget(context, widget.device);
  }
}
