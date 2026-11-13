import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/material.dart';

import 'universal_remote_item.dart';
import '../definitions/remote_item_definition.dart';
import '../layout/models/grid_layout.dart';
import '../layout/models/square_grid_metrics.dart';
import 'models/resize_candidate.dart';
import 'mouse_item_drag.dart';
import 'resize_handle.dart';
import 'styled_item.dart';

class UniversalRemoteItemState extends State<UniversalRemoteItem> {
  int? _resizePointer;
  Offset _startPosition = Offset.zero;
  ({int width, int height})? _requested;
  ResizeCandidate? _preview;
  bool resizing = false;
  Size _stride = Size.zero;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _layout);

  Widget get _content => StyledItem(style: widget.style, child: widget.child);
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
    color: widget.style.showBackground
        ? Theme.of(context).colorScheme.surfaceContainerHigh
        : Colors.transparent,
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

  /// The last valid footprint, drawn over the grid without taking part in
  /// layout. It only ever shows a size and place that can be applied.
  Widget _ghost(BuildContext context) {
    final preview = _preview!;
    final cell = Size(
      _stride.width - SquareGridMetrics.gap,
      _stride.height - SquareGridMetrics.gap,
    );
    return Positioned(
      left: preview.dx * _stride.width,
      top: preview.dy * _stride.height,
      width: SquareGridMetrics.extent(preview.width, cell.width),
      height: SquareGridMetrics.extent(preview.height, cell.height),
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  ResizeCandidate get _unchanged =>
      (dx: 0, dy: 0, width: widget.width, height: widget.height);

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
      _requested = (width: widget.width, height: widget.height);
      _preview = _unchanged;
      resizing = true;
    });
  }

  /// Snaps the pointer to whole cells and asks for the nearest valid
  /// footprint only when the snapped request changes. An invalid request
  /// keeps the last valid preview.
  void _update(PointerMoveEvent event) {
    if (event.pointer != _resizePointer) {
      return;
    }
    final requested = _sizeAt(event.position);
    if (requested == _requested) {
      return;
    }
    _requested = requested;
    final candidate = widget.resolveResize(requested.width, requested.height);
    if (candidate == null || candidate == _preview) {
      return;
    }
    setState(() => _preview = candidate);
  }

  /// Pointer movement in whole cells, in any direction, never below the
  /// effective minimum or above the largest allowed size.
  ({int width, int height}) _sizeAt(Offset position) {
    final delta = position - _startPosition;
    final width = widget.width + (delta.dx / _stride.width).round();
    final height = widget.height + (delta.dy / _stride.height).round();
    return (
      width: _bounded(width, widget.minimumWidth, GridLayout.maxColumns),
      height: _bounded(
        height,
        widget.minimumHeight,
        RemoteItemDefinition.maximumHeight,
      ),
    );
  }

  int _bounded(int value, int minimum, int maximum) =>
      value.clamp(minimum, maximum < minimum ? minimum : maximum);

  /// Applies the last valid preview in one change; nothing when unchanged.
  void _end(PointerUpEvent event) {
    if (event.pointer != _resizePointer) {
      return;
    }
    final preview = _preview;
    _cancel();
    if (preview == null || preview == _unchanged) {
      return;
    }
    widget.onResize(preview);
  }

  void _cancelPointer(PointerCancelEvent event) {
    if (event.pointer == _resizePointer) {
      _cancel();
    }
  }

  /// Drops the preview; a cancelled gesture leaves the item as it was.
  void _cancel() => setState(() {
    resizing = false;
    _requested = null;
    _preview = null;
    _resizePointer = null;
  });
}
