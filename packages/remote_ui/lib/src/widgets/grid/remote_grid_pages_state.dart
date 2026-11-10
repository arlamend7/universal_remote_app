import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../layout/models/grid_item.dart';
import '../../layout/models/square_grid_metrics.dart';

import 'grid_page_dots.dart';
import 'remote_grid_pages.dart';
import 'square_grid_surface.dart';

class RemoteGridPagesState extends State<RemoteGridPages> {
  late int _index = widget.layout.pageStarts
      .indexOf(widget.initialPage)
      .clamp(0, widget.layout.pageStarts.length - 1);
  late final _pages = PageController(initialPage: _index);

  final _controlPointers = <int>{};
  PointerDownEvent? _swipeStart;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.layout.pageStarts.length;
    if (count == 1) {
      return _surface(0);
    }
    final index = _index.clamp(0, count - 1);
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pages,
            physics: widget.swipeOnCanvas
                ? null
                : const NeverScrollableScrollPhysics(),
            itemCount: count,
            onPageChanged: _select,
            itemBuilder: (_, page) => _surface(page),
          ),
        ),
        SafeArea(
          top: false,
          child: GridPageDots(
            count: count,
            selected: index,
            onSelected: _navigate,
          ),
        ),
      ],
    );
  }

  Widget _surface(int index) {
    final layout = widget.layout;
    final start = layout.pageStarts[index];
    final end = layout.pageEnd(index);
    final page = layout.pageLayout(index);
    return LayoutBuilder(
      key: ValueKey(start),
      builder: (context, constraints) {
        final fits =
            SquareGridMetrics.extent(end - start, page.cellSize) <=
            constraints.maxWidth + .001;
        final canPage = layout.pageStarts.length > 1;
        final surface = SquareGridSurface(
          layout: page,
          columns: end - start,
          rows: page.rows,
          itemBuilder: _control,
          allowsPageGesture: () => _controlPointers.isEmpty,
          onHorizontalOverflow: canPage
              ? (direction) => _navigate(index + direction)
              : null,
        );
        if (widget.swipeOnCanvas || !canPage || !fits) {
          return surface;
        }
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _startSwipe,
          onPointerUp: (event) => _finishSwipe(context, event),
          onPointerCancel: (_) => _swipeStart = null,
          child: surface,
        );
      },
    );
  }

  Widget _control(GridItem item) {
    final child = widget.itemBuilder(item);
    if (widget.ownsDragGesture?.call(item) != true) {
      return child;
    }
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _controlPointers.add(event.pointer),
      onPointerUp: (event) => _controlPointers.remove(event.pointer),
      onPointerCancel: (event) => _controlPointers.remove(event.pointer),
      child: child,
    );
  }

  // Observe live swipes without entering the gesture arena with the TV controls.
  void _startSwipe(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.touch ||
        _controlPointers.contains(event.pointer) ||
        _swipeStart != null) {
      _swipeStart = null;
      return;
    }
    _swipeStart = event;
  }

  void _finishSwipe(BuildContext context, PointerUpEvent event) {
    final start = _swipeStart;
    _swipeStart = null;
    if (start == null ||
        start.pointer != event.pointer ||
        event.timeStamp - start.timeStamp >=
            const Duration(milliseconds: 500)) {
      return;
    }
    final delta = event.position - start.position;
    if (delta.dx.abs() < 55 || delta.dx.abs() < delta.dy.abs() * 1.5) {
      return;
    }
    final forward =
        (delta.dx < 0) == (Directionality.of(context) == TextDirection.ltr);
    _navigate(_index + (forward ? 1 : -1));
  }

  void _select(int index) {
    if (_index == index) {
      return;
    }
    setState(() => _index = index);
    widget.onPageChanged?.call(widget.layout.pageStarts[index]);
  }

  void _navigate(int index) {
    if (!_pages.hasClients ||
        index == _index ||
        index < 0 ||
        index >= widget.layout.pageStarts.length) {
      return;
    }
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}
