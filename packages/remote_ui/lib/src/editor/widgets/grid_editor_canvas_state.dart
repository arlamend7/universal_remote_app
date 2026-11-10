import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../../layout/models/square_grid_metrics.dart';
import 'grid_edit_tile.dart';
import 'grid_editor_canvas.dart';
import 'grid_editor_page_geometry.dart';
import 'empty_slot_outline.dart';
import 'grid_drag_scroll.dart';

class GridEditorCanvasState extends State<GridEditorCanvas>
    with SingleTickerProviderStateMixin {
  final target = GlobalKey();
  GridItem? ghost;
  late List<GridEditorPageGeometry> _pages;
  final _scrollers = <GridDragScroll>[];
  late final Ticker _scrollTicker = createTicker(_scrollFrame);
  Duration _lastFrame = Duration.zero;
  Offset? _pointer;
  Offset _grabOffset = Offset.zero;
  int? _pointerId;
  DragTargetDetails<String>? _drag;
  final _extraRows = <int, int>{};
  int _extraColumns = 0;

  List<GridEditorPageGeometry> _geometry() {
    final model = widget.model;
    final layout = model.draft;
    var left = 0.0;
    return [
      for (final (index, start) in layout.pageStarts.indexed)
        _pageAt(index, start, left, (end) => left = end),
    ];
  }

  GridEditorPageGeometry _pageAt(
    int index,
    int start,
    double left,
    ValueChanged<double> advance,
  ) {
    final model = widget.model;
    final layout = model.draft;
    final last = index == layout.pageStarts.length - 1;
    final page = GridEditorPageGeometry(
      start: start,
      columns: model.isGroup
          ? model.columns
          : layout.pageColumns(index) + (last ? 1 + _extraColumns : 0),
      rows: model.isGroup
          ? model.maxRows
          : math.min(
              model.maxRows,
              layout.pageRows(index) + 1 + (_extraRows[start] ?? 0),
            ),
      left: left,
      side: layout.pageCellSize(index),
    );
    advance(page.end);
    return page;
  }

  @override
  void dispose() {
    _scrollTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _layout);

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    _pages = _geometry();
    return Listener(
      onPointerDown: _trackPointer,
      onPointerMove: _trackMovement,
      onPointerUp: _releasePointer,
      onPointerCancel: _releasePointer,
      child: DragTarget<String>(
        hitTestBehavior: HitTestBehavior.opaque,
        onWillAcceptWithDetails: (_) => !widget.model.saving,
        onMove: _move,
        onLeave: (_) {
          if (_pointerId == null) {
            _clearDrag();
          }
        },
        onAcceptWithDetails: _accept,
        builder: (_, candidate, rejected) =>
            Align(alignment: Alignment.topLeft, child: _canvas(context)),
      ),
    );
  }

  void _trackPointer(PointerDownEvent event) {
    if (_pointerId != null) {
      return;
    }
    _pointerId = event.pointer;
    _pointer = event.position;
  }

  void _trackMovement(PointerMoveEvent event) {
    if (event.pointer == _pointerId) {
      _pointer = event.position;
    }
  }

  void _releasePointer(PointerEvent event) {
    if (event.pointer != _pointerId) {
      return;
    }
    _pointerId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pointerId == null && _drag != null) {
        _clearDrag();
      }
    });
  }

  Widget _canvas(BuildContext context) {
    final slotCount = _pages.fold(
      0,
      (count, page) => count + page.rows * page.columns,
    );
    return SizedBox(
      key: target,
      width: _pages.last.end - SquareGridMetrics.gap,
      height: _pages.fold<double>(
        0.0,
        (height, page) => math.max(height, page.height),
      ),
      child: Stack(
        children: [
          if (widget.onAdd != null && slotCount > 400)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _addAt(details.localPosition),
              ),
            ),
          for (final item in widget.model.draft.items) _tile(item),
          if (widget.onAdd != null && ghost == null && slotCount <= 400)
            ..._slots(),
          if (ghost != null) _ghost(context, ghost!),
        ],
      ),
    );
  }

  GridEditorPageGeometry _pageForColumn(int column) => _pages.firstWhere(
    (page) => page.contains(column),
    orElse: () => _pages.last,
  );

  GridEditorPageGeometry _pageForPixel(double x) =>
      _pages.firstWhere((page) => x < page.end, orElse: () => _pages.last);

  Widget _tile(GridItem item) => Positioned.fromRect(
    key: ValueKey(item.id),
    rect: _pageForColumn(item.x).rect(item),
    child: GridEditTile(
      item: item,
      model: widget.model,
      dependencies: widget.dependencies,
      onEdit: widget.onEdit,
    ),
  );

  void _addAt(Offset position) {
    final page = _pageForPixel(position.dx);
    final y = (position.dy / page.stride).floor();
    if (y >= page.rows || y < widget.model.reservedRows) {
      return;
    }
    widget.onAdd?.call((
      x: page.start + ((position.dx - page.left) / page.stride).floor(),
      y: y,
    ));
  }

  Iterable<Widget> _slots() sync* {
    final occupied = <(int, int)>{
      for (final item in widget.model.draft.items)
        for (var y = item.y; y < item.y + item.h; y++)
          for (var x = item.x; x < item.x + item.w; x++) (x, y),
    };
    for (final page in _pages) {
      yield* _pageSlots(page, occupied);
    }
  }

  Iterable<Widget> _pageSlots(
    GridEditorPageGeometry page,
    Set<(int, int)> occupied,
  ) sync* {
    for (var y = widget.model.reservedRows; y < page.rows; y++) {
      yield* _slotRow(page, y, occupied);
    }
  }

  Iterable<Widget> _slotRow(
    GridEditorPageGeometry page,
    int y,
    Set<(int, int)> occupied,
  ) sync* {
    for (var offset = 0; offset < page.columns; offset++) {
      final x = page.start + offset;
      if (!occupied.contains((x, y))) {
        yield Positioned(
          left: page.left + offset * page.stride,
          top: y * page.stride,
          width: page.side,
          height: page.side,
          child: _addButton(x, y),
        );
      }
    }
  }

  Widget _addButton(int x, int y) {
    final colors = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: EmptySlotOutline(colors.outlineVariant),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: colors.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: widget.model.saving
            ? null
            : () => widget.onAdd?.call((x: x, y: y)),
        child: Tooltip(
          message: 'Add control at column ${x + 1}, row ${y + 1}',
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              spacing: 3,
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.add, size: 17), Text('Add')],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ghost(BuildContext context, GridItem item) => Positioned.fromRect(
    rect: _pageForColumn(item.x).rect(item),
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            width: 3,
            color: widget.model.canReplace(item)
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
  GridItem? _candidate(String id, Offset offset) {
    final item = widget.model.draft.items
        .where((item) => item.id == id)
        .firstOrNull;
    final box = target.currentContext?.findRenderObject() as RenderBox?;
    if (item == null || box == null) {
      return null;
    }
    final local = box.globalToLocal(offset);
    final page = _pageForPixel(local.dx);
    final column = ((local.dx - page.left) / page.stride).round();
    final row = (local.dy / page.stride).round();
    return item.copy(
      x:
          page.start +
          column.clamp(
            0,
            widget.model.isGroup ? page.columns - item.w : page.columns - 1,
          ),
      y: row.clamp(
        widget.model.reservedRows,
        widget.model.isGroup ? page.rows - item.h : page.rows - 1,
      ),
    );
  }

  void _move(DragTargetDetails<String> details) {
    final firstMove = _drag == null;
    _drag = details;
    final pointer = _pointer;
    if (pointer != null) {
      _grabOffset = pointer - details.offset;
    }
    _updateGhost(details.offset);
    if (firstMove) {
      _startScroll();
    }
  }

  void _startScroll() {
    for (final axis in Axis.values) {
      final scrollable = Scrollable.maybeOf(context, axis: axis);
      if (scrollable != null) {
        _scrollers.add(GridDragScroll(scrollable));
      }
    }
    if (_scrollers.isNotEmpty) {
      _lastFrame = Duration.zero;
      _scrollTicker.start();
    }
  }

  void _scrollFrame(Duration elapsed) {
    final seconds = ((elapsed - _lastFrame).inMicroseconds / 1000000).clamp(
      0.0,
      .032,
    );
    _lastFrame = elapsed;
    final pointer = _pointer;
    if (pointer == null) {
      return;
    }
    var scrolled = false;
    for (final scroller in _scrollers) {
      if (scroller.advance(pointer, seconds)) {
        scrolled = true;
      }
    }
    if (scrolled) {
      _updateGhost(pointer - _grabOffset);
    }
  }

  void _updateGhost(Offset offset) {
    final drag = _drag;
    if (drag == null || !mounted) {
      return;
    }
    final item = _candidate(drag.data, offset);
    final page = item == null ? null : _pageForColumn(item.x);
    final expand = item != null && page != null && !widget.model.isGroup;
    final growDown =
        expand &&
        item.y + item.h >= page.rows - 1 &&
        page.rows < widget.model.maxRows;
    final growRight =
        expand &&
        page == _pages.last &&
        item.x + item.w >= page.start + page.columns - 1 &&
        page.start + page.columns < GridLayout.coordinateLimit;
    if (!growDown && !growRight && item?.x == ghost?.x && item?.y == ghost?.y) {
      return;
    }
    setState(() {
      ghost = item;
      if (growDown) {
        _extraRows.update(page.start, (rows) => rows + 4, ifAbsent: () => 4);
      }
      if (growRight) {
        _extraColumns += 4;
      }
    });
  }

  void _stopScroll() {
    _drag = null;
    _scrollTicker.stop();
    _scrollers.clear();
  }

  void _clearDrag() {
    _stopScroll();
    setState(() {
      ghost = null;
      _extraRows.clear();
      _extraColumns = 0;
    });
  }

  void _accept(DragTargetDetails<String> details) {
    final item = _candidate(details.data, details.offset);
    _clearDrag();
    if (item != null) {
      widget.model.move(item);
    }
  }
}
