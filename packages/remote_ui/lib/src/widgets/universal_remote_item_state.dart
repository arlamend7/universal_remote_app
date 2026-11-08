import 'package:flutter/material.dart';

import '../configuration/remote_item_style.dart';
import 'universal_remote_item.dart';
import 'mouse_item_drag.dart';
import 'resize_handle.dart';

class UniversalRemoteItemState extends State<UniversalRemoteItem> {
  Offset delta = Offset.zero;
  bool resizing = false;
  Size origin = Size.zero;
  @override
  Widget build(BuildContext context) {
    if (widget.onResize == null) {
      return _content;
    }
    return LayoutBuilder(builder: _layout);
  }

  Widget get _content {
    final styled = _styledContent();
    if (widget.quarterTurns == 0) {
      return styled;
    }
    return RotatedBox(quarterTurns: widget.quarterTurns, child: styled);
  }

  Widget _styledContent() {
    final style = widget.style;
    if (style.isDefault) {
      return widget.child;
    }
    final foreground = style.foreground;
    final background = style.background;
    Widget content = Padding(
      padding: EdgeInsets.all(style.padding),
      child: widget.child,
    );
    if (foreground != null) {
      content = _foreground(content, Color(foreground));
    }
    final radius = BorderRadius.circular(style.cornerRadius);
    return Opacity(
      opacity: style.opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background == null ? null : Color(background),
          borderRadius: radius,
          border: style.showBorder ? _border(style) : null,
        ),
        child: content,
      ),
    );
  }

  Border _border(RemoteItemStyle style) => Border.all(
    width: style.borderWidth,
    color: style.borderColor == null
        ? Theme.of(context).colorScheme.outline
        : Color(style.borderColor!),
  );

  Widget _foreground(Widget child, Color color) => IconTheme.merge(
    data: IconThemeData(color: color),
    child: DefaultTextStyle.merge(
      style: TextStyle(color: color),
      child: child,
    ),
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
        color: widget.selected
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
    onCancel: () => setState(() => resizing = false),
  );
  Widget _ghost(BuildContext context) => Positioned(
    left: 0,
    top: 0,
    width: (origin.width + delta.dx).clamp(48, 1000),
    height: (origin.height + delta.dy).clamp(48, 1600),
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
  void _start(DragStartDetails details) => setState(() {
    resizing = true;
    origin = context.size!;
    delta = Offset.zero;
  });
  void _update(DragUpdateDetails details) =>
      setState(() => delta += details.delta);
  void _end(DragEndDetails details) {
    final cellWidth = (origin.width + 8) / widget.width;
    final cellHeight = (origin.height + 8) / widget.height;
    final width = widget.width + (delta.dx / cellWidth).round();
    final height = widget.height + (delta.dy / cellHeight).round();
    setState(() => resizing = false);
    widget.onResize?.call(width.clamp(1, 4), height.clamp(1, 16));
  }
}
