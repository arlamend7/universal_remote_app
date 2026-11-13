import 'package:flutter/foundation.dart';
import 'package:remote_core/remote_core.dart';

import '../definitions/enums/item_axis.dart';
import '../definitions/remote_item_registry.dart';
import '../layout/grid_arrangement.dart';
import '../layout/grid_geometry.dart';
import '../layout/grid_resize_resolver.dart';
import '../layout/models/enums/editor_mode.dart';
import '../layout/models/grid_item.dart';
import '../layout/models/grid_layout.dart';
import '../layout/models/grid_page_size.dart';
import 'device_grids_controller.dart';

final class GridEditorViewModel extends ChangeNotifier {
  GridEditorViewModel(
    this.grids,
    this.device, {
    GridLayout? initial,
    int? columns,
    int? maxRows,
    this.reservedRows = 0,
  }) : _groupColumns = columns,
       _groupRows = maxRows,
       draft = initial ?? grids.layoutFor(device);
  final DeviceGridsController grids;
  final RemoteDevice device;
  final int? _groupColumns, _groupRows;
  final int reservedRows;
  int get columns => _groupColumns ?? draft.canvasColumns;
  bool get isGroup => _groupRows != null;

  int _pageStart = 0;
  int get pageStart => draft.pageStarts.contains(_pageStart) ? _pageStart : 0;

  void selectPage(int start) {
    if (start == pageStart || !draft.pageStarts.contains(start)) {
      return;
    }
    _pageStart = start;
    notifyListeners();
  }

  void addPage() {
    if (isGroup ||
        columns + GridLayout.defaultColumns > GridLayout.coordinateLimit) {
      return;
    }
    change(
      draft.withCanvas(
        columns: columns + GridLayout.defaultColumns,
        rows: draft.configuredRows ?? GridLayout.defaultRows,
        pageStarts: [...draft.pageStarts, columns],
        pageSizes: {
          ...draft.pageSizes,
          columns: GridPageSize(
            draft.pageRows(draft.pageIndexAt(pageStart)),
            draft.pageCellSize(draft.pageIndexAt(pageStart)),
          ),
        },
      ),
    );
  }

  bool move(GridItem item) {
    final original = draft.items
        .where((control) => control.id == item.id)
        .firstOrNull;
    if (original == null || (item.x == original.x && item.y == original.y)) {
      return false;
    }
    final next = _arrange(draft, item);
    if (next == null) {
      return false;
    }
    _pageStart = next.pageStarts.lastWhere((start) => start <= item.x);
    change(next);
    return true;
  }

  int get maxRows => _groupRows ?? GridLayout.coordinateLimit;
  GridLayout draft;
  EditorMode mode = EditorMode.edit;
  void setMode(EditorMode value) {
    mode = value;
    notifyListeners();
  }

  final _undo = <GridLayout>[];
  final _redo = <GridLayout>[];
  String? selected;
  String? error;
  bool saving = false;
  void setDimensions(int columns, int rows, {double? cellSize}) {
    if (isGroup ||
        columns < GridLayout.defaultColumns ||
        rows < 1 ||
        rows > GridLayout.coordinateLimit) {
      return;
    }
    final index = draft.pageIndexAt(pageStart);
    final page = draft.pageLayout(index);
    if (columns < page.occupiedColumns || rows < page.occupiedRows) {
      return;
    }
    final side = cellSize ?? page.cellSize;
    final shift = columns - page.columns;
    if (shift == 0 && rows == page.rows && side == page.cellSize) {
      return;
    }
    final end = draft.pageEnd(index);
    final next = _shiftPages(end, shift, draft.items);
    change(
      next.withCanvas(
        columns: next.columns,
        rows: next.configuredRows ?? GridLayout.defaultRows,
        pageSizes: {...next.pageSizes, pageStart: GridPageSize(rows, side)},
      ),
    );
  }

  void deletePage() {
    if (isGroup || pageStart == 0) {
      return;
    }
    final start = pageStart;
    final index = draft.pageIndexAt(start);
    final end = draft.pageEnd(index);
    final kept = draft.items.where((item) => item.x < start || item.x >= end);
    final next = _shiftPages(end, start - end, kept, removeStart: start);
    change(next);
    selectPage(next.pageStarts[index - 1]);
  }

  GridLayout _shiftPages(
    int from,
    int shift,
    Iterable<GridItem> items, {
    int? removeStart,
  }) {
    int moved(int column) => column >= from ? column + shift : column;
    return draft
        .withItems(
          items.map(
            (item) => item.x >= from ? item.copy(x: moved(item.x)) : item,
          ),
        )
        .withCanvas(
          columns: draft.canvasColumns + shift,
          rows: draft.configuredRows ?? GridLayout.defaultRows,
          pageStarts: [
            for (final start in draft.pageStarts)
              if (start != removeStart) moved(start),
          ],
          pageSizes: {
            for (final entry in draft.pageSizes.entries)
              if (entry.key != removeStart) moved(entry.key): entry.value,
          },
        );
  }

  bool _disposed = false;
  int _sequence = 0;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  GridItem? get selection =>
      draft.items.where((item) => item.id == selected).firstOrNull;
  void select(String? id) {
    if (_disposed || selected == id) {
      return;
    }
    selected = id;
    notifyListeners();
  }

  void change(GridLayout next) {
    if (saving || _disposed) {
      return;
    }
    if ((!isGroup && !next.hasValidCanvas) ||
        next.items.any((item) => item.y < reservedRows) ||
        !GridGeometry.valid(
          next.items,
          columns: _groupColumns ?? next.canvasColumns,
          rows: _groupRows ?? next.rows,
        )) {
      error = 'That position or size overlaps a control or does not fit.';
      notifyListeners();
      return;
    }
    _undo.add(draft);
    if (_undo.length > 50) {
      _undo.removeAt(0);
    }
    _redo.clear();
    draft = next;
    error = null;
    notifyListeners();
  }

  GridItem? add(String definitionId, {({int x, int y})? at}) {
    if (saving || _disposed) {
      return null;
    }
    final definition = RemoteItemRegistry.resolve(definitionId);
    final item = GridItem(
      id: 'widget-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}',
      definitionId: definitionId,
      x: at?.x ?? 0,
      y: at?.y ?? reservedRows,
      w: definition.width.clamp(1, columns),
      h: definition.height,
      position: definition.supportsPosition ? definition.defaultPosition : null,
    );
    final next = at == null ? _append(item) : _insert(item);
    if (next == null) {
      error =
          'No room for this control here. Try another slot or free some space.';
      notifyListeners();
      return null;
    }
    final added = next.items.firstWhere((candidate) => candidate.id == item.id);
    selected = added.id;
    change(next);
    return added;
  }

  GridLayout? _append(GridItem item) {
    final index = draft.pageIndexAt(pageStart);
    final page = isGroup ? draft : draft.pageLayout(index);
    final placed = GridGeometry.place(
      item,
      page.items,
      columns: isGroup ? columns : page.columns,
      rows: isGroup ? maxRows : page.rows + item.h,
      startRow: reservedRows,
    );
    return placed == null
        ? null
        : _insert(placed.copy(x: placed.x + pageStart), grow: true);
  }

  /// Adds [item] at its default size, or its minimum when that is all that
  /// fits. Only appending may add rows to the page; a chosen slot never does.
  GridLayout? _insert(GridItem item, {bool grow = false}) {
    final definition = item.definition;
    final source = draft.withItems([...draft.items, item]);
    for (final size in [
      (item.w, item.h),
      (definition.minimumWidth, definition.minimumHeight),
    ]) {
      final candidate = item.copy(w: size.$1, h: size.$2);
      final next = _arrange(source, candidate, grow: grow);
      if (next != null) {
        return next;
      }
    }
    return null;
  }

  void update(GridItem item) => change(
    draft.withItems(draft.items.map((old) => old.id == item.id ? item : old)),
  );
  void replace(GridItem item) {
    final next = _arrange(draft, item);
    if (next == null) {
      error = _placementProblem(item);
      notifyListeners();
      return;
    }
    change(next);
  }

  String _placementProblem(GridItem item) {
    final size = '${item.w} × ${item.h}';
    if (!item.definition.acceptsArranged(item.w, item.h, item.arrangement)) {
      return '${item.definition.name} does not support $size blocks.';
    }
    if (!draft.staysOnPage(item) || !_insidePage(draft, item)) {
      return 'A $size control would cross the page boundary.';
    }
    if (isGroup && (item.x + item.w > columns || item.y + item.h > maxRows)) {
      return 'A $size control would extend outside this group.';
    }
    final blocker = draft.items
        .where(
          (other) => other.id != item.id && GridGeometry.overlaps(item, other),
        )
        .firstOrNull;
    if (blocker != null) {
      return 'A $size control would overlap ${blocker.definition.name}.';
    }
    return 'This control cannot fit at $size blocks in its current position.';
  }

  bool canReplace(GridItem item) => _arrange(draft, item) != null;

  /// [item] at its own size: where it stands, or at the nearest free slot on
  /// its page (or group). Null when there is no room; nothing shrinks.
  GridItem? placementFor(GridItem item) =>
      resolveResize(item, item.w, item.h, shrinkToFit: false);

  /// The nearest valid footprint for [item] at [width] by [height], from the
  /// shared [GridResizeResolver]: clamped to its effective minimum and the
  /// page, kept in place when it fits, otherwise moved to the nearest free
  /// slot and (with [shrinkToFit]) made only as much smaller as needed.
  /// Other controls never move and the grid never grows. Null when nothing
  /// valid exists.
  GridItem? resolveResize(
    GridItem item,
    int width,
    int height, {
    bool shrinkToFit = true,
  }) {
    final resolved = _resolveOnPage(item, width, height, shrinkToFit);
    if (resolved == null || !canReplace(resolved)) {
      return null;
    }
    return resolved;
  }

  GridItem? _resolveOnPage(
    GridItem item,
    int width,
    int height,
    bool shrinkToFit,
  ) {
    final others = draft.withItems(
      draft.items.where((other) => other.id != item.id),
    );
    if (isGroup) {
      return GridResizeResolver.resolve(
        item,
        width,
        height,
        others.items,
        columns: columns,
        rows: maxRows,
        startRow: reservedRows,
        shrinkToFit: shrinkToFit,
      );
    }
    final index = others.pageIndexAt(item.x);
    final start = others.pageStarts[index];
    final page = others.pageLayout(index);
    final resolved = GridResizeResolver.resolve(
      item.copy(x: item.x - start),
      width,
      height,
      page.items,
      columns: page.columns,
      rows: page.rows,
      startRow: reservedRows,
      shrinkToFit: shrinkToFit,
    );
    return resolved?.copy(x: resolved.x + start);
  }

  /// Arranges [item]'s elements along [next], swapping its width and height
  /// (and so its effective minimum) in one change. Moves it to the nearest
  /// free slot when the swapped footprint does not fit where it is.
  bool changePosition(GridItem item, ItemAxis next) {
    final swapped = item.withPosition(next);
    if (identical(swapped, item)) {
      return true;
    }
    final placed = placementFor(swapped);
    if (placed == null) {
      error = noRoomFor(swapped);
      notifyListeners();
      return false;
    }
    replace(placed);
    return error == null;
  }

  /// Why [item] cannot be placed anywhere on its page.
  String noRoomFor(GridItem item) =>
      'This control has no room for a ${item.w} × ${item.h} footprint on this page.';

  /// Whether [item]'s whole footprint lies inside its page's configured
  /// columns and rows.
  bool _insidePage(GridLayout source, GridItem item) {
    final others = source.withItems(
      source.items.where((other) => other.id != item.id),
    );
    final index = others.pageIndexAt(item.x);
    return item.x + item.w <= others.pageEnd(index) &&
        item.y + item.h <= others.pageRows(index);
  }

  GridLayout? _arrange(GridLayout source, GridItem item, {bool grow = false}) {
    if (isGroup) {
      return GridArrangement.replace(
        source,
        item,
        columns: columns,
        rows: maxRows,
        reservedRows: reservedRows,
      );
    }
    if (!grow && !_insidePage(source, item)) {
      return null;
    }
    final next = source.withItems(
      source.items.map((old) => old.id == item.id ? item : old),
    );
    final index = next.pageIndexAt(item.x);
    final anchor = next.pageStarts[index];
    final expanded = next.withCanvas(
      columns: next.canvasColumns,
      rows: next.configuredRows ?? GridLayout.defaultRows,
      pageSizes: {
        ...next.pageSizes,
        if (item.y + item.h > draft.pageRows(index))
          anchor: GridPageSize(item.y + item.h, draft.pageCellSize(index)),
      },
    );
    if (!expanded.hasValidCanvas ||
        !GridGeometry.valid(
          expanded.items,
          columns: expanded.canvasColumns,
          rows: expanded.rows,
        )) {
      return null;
    }
    return expanded;
  }

  /// Resizes [item] towards [width] by [height] through the shared resolver,
  /// in one change. Keeps the draft as it is when nothing valid exists.
  void resize(GridItem item, int width, int height) {
    final resolved = resolveResize(item, width, height);
    if (resolved == null) {
      error = noRoomFor(item.copy(w: width, h: height));
      notifyListeners();
      return;
    }
    applyResize(resolved);
  }

  /// Commits a footprint chosen by [resolveResize]: size and place together.
  void applyResize(GridItem resolved) => replace(resolved);
  void remove(String id) {
    selected = null;
    change(draft.withItems(draft.items.where((item) => item.id != id)));
  }

  void undo() {
    if (!canUndo || saving) {
      return;
    }
    _redo.add(draft);
    draft = _undo.removeLast();
    selected = null;
    error = null;
    notifyListeners();
  }

  void redo() {
    if (!canRedo || saving) {
      return;
    }
    _undo.add(draft);
    draft = _redo.removeLast();
    selected = null;
    error = null;
    notifyListeners();
  }

  void reset() =>
      change(_groupRows != null ? draft.withItems([]) : grids.defaultLayout());
  Future<bool> save() async {
    if (saving) {
      return false;
    }
    saving = true;
    notifyListeners();
    try {
      await grids.save(device, draft);
      return true;
    } catch (_) {
      error = 'Could not save this layout. Please retry.';
      return false;
    } finally {
      if (!_disposed) {
        saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
