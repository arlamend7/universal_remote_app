import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/material.dart';

import 'universal_remote_item.dart';
import '../layout/models/grid_layout.dart';
import '../layout/models/square_grid_metrics.dart';
import 'mouse_item_drag.dart';
import 'resize_handle.dart';
import 'styled_item.dart';

class UniversalRemoteItemState extends State<UniversalRemoteItem> {
  int? _resizePointer;
  Offset _startPosition = Offset.zero;
  ({int width, int height})? _pendingSize;
  bool resizing = false;
  Size _stride = Size.zero;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _layout);

  Widget get _content => StyledItem(
    style: widget.style,
    quarterTurns: widget.quarterTurns,
    child: widget.child,
  );
  Widget _layout(BuildContext context, BoxConstraints constraints) => Semantics(
    button: true,
    label: '${widget.label}. Tap to edit, drag with a mouse or hold to move.',
    selected: widget.selected,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: _draggable(context, constraints)),
        Positioned(top: -12, left: -12, child: _remove(context)),
        Positioned(bottom: 0, right: 0, child: _resize()),
        if (resizing) _ghost(context),
      ],
    ),
  );
  Widget _draggable(BuildContext context, BoxConstraints constraints) {
    final feedback = Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: _content,
      ),
    );
    final placeholder = Opacity(opacity: .25, child: _surface(context));
    return MouseItemDrag(
      data: widget.id,
      maxSimultaneousDrags: widget.enabled ? 1 : 0,
      dragAnchorStrategy: childDragAnchorStrategy,
      feedback: feedback,
      childWhenDragging: placeholder,
      child: LongPressDraggable<String>(
        data: widget.id,
        maxSimultaneousDrags: widget.enabled ? 1 : 0,
        dragAnchorStrategy: childDragAnchorStrategy,
        feedback: feedback,
        childWhenDragging: placeholder,
        child: _surface(context),
      ),
    );
  }

  Widget _surface(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: widget.selected && !resizing
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).dividerColor,
        width: widget.selected ? 2 : 1,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: widget.enabled ? widget.onEdit : null,
      child: _content,
    ),
  );
  Widget _remove(BuildContext context) => IconButton(
    tooltip: 'Remove ${widget.label}',
    constraints: const BoxConstraints.tightFor(width: 40, height: 40),
    onPressed: widget.enabled ? widget.onRemove : null,
    iconSize: 18,
    icon: CircleAvatar(
      radius: 12,
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      child: Icon(
        Icons.remove,
        size: 16,
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    ),
  );
  Widget _resize() => ResizeHandle(
    label: widget.label,
    enabled: widget.enabled,
    onStart: _start,
    onUpdate: _update,
    onEnd: _end,
    onCancel: _cancelPointer,
  );
  Widget _ghost(BuildContext context) {
    final size = _pendingSize!;
    final valid = widget.canResize?.call(size.width, size.height) ?? true;
    final colors = Theme.of(context).colorScheme;
    return Positioned(
      left: 0,
      top: 0,
      width: SquareGridMetrics.extent(
        size.width,
        _stride.width - SquareGridMetrics.gap,
      ),
      height: SquareGridMetrics.extent(
        size.height,
        _stride.height - SquareGridMetrics.gap,
      ),
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 2,
              color: valid ? colors.primary : colors.error,
            ),
          ),
        ),
      ),
    );
  }

  void _start(PointerDownEvent event) {
    if (_resizePointer != null || event.buttons != kPrimaryButton) {
      return;
    }
    setState(() {
      final size = context.size!;
      const gap = SquareGridMetrics.gap;
      _stride = Size(
        (size.width + gap) / widget.width,
        (size.height + gap) / widget.height,
      );
      _startPosition = event.position;
      _resizePointer = event.pointer;
      _pendingSize = (width: widget.width, height: widget.height);
      resizing = true;
    });
  }

  void _update(PointerMoveEvent event) {
    if (event.pointer != _resizePointer) {
      return;
    }
    final size = _sizeAt(event.position);
    if (size != _pendingSize) {
      setState(() => _pendingSize = size);
    }
  }

  ({int width, int height}) _sizeAt(Offset position) {
    final delta = position - _startPosition;
    final width = widget.width + (delta.dx / _stride.width).round();
    final height = widget.height + (delta.dy / _stride.height).round();
    return (
      width: width.clamp(
        1,
        widget.quarterTurns.isOdd ? 16 : GridLayout.maxColumns,
      ),
      height: height.clamp(
        1,
        widget.quarterTurns.isOdd ? GridLayout.maxColumns : 16,
      ),
    );
  }

  void _end(PointerUpEvent event) {
    if (event.pointer != _resizePointer) {
      return;
    }
    final size = _sizeAt(event.position);
    _cancel();
    if (size.width != widget.width || size.height != widget.height) {
      widget.onResize(size.width, size.height);
    }
  }

  void _cancelPointer(PointerCancelEvent event) {
    if (event.pointer == _resizePointer) {
      _cancel();
    }
  }

  void _cancel() => setState(() {
    resizing = false;
    _pendingSize = null;
    _resizePointer = null;
  });
}
