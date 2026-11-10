import 'dart:convert';
import 'dart:math' as math;

import 'grid_item.dart';
import 'grid_page_size.dart';
import 'square_grid_metrics.dart';

final class GridLayout {
  GridLayout(
    Iterable<GridItem> items, {
    this.columns = defaultColumns,
    this.configuredRows,
    this.cellSize = SquareGridMetrics.minimumCell,
    List<int> pageStarts = const [0],
    Map<int, GridPageSize> pageSizes = const {},
  }) : items = List.unmodifiable(items),
       pageStarts = List.unmodifiable(pageStarts),
       pageSizes = Map.unmodifiable(pageSizes);

  static const defaultColumns = 4;
  static const defaultRows = 8;
  static const maxColumns = 8;
  static const maxRows = 128;
  static const coordinateLimit = 1000000;

  final List<GridItem> items;
  final int columns;
  final int? configuredRows;
  final double cellSize;
  final List<int> pageStarts;
  final Map<int, GridPageSize> pageSizes;

  int pageIndexAt(int column) => pageStarts
      .lastIndexWhere((start) => start <= column)
      .clamp(0, pageStarts.length - 1);
  double pageOffset(int index) {
    var offset = 0.0;
    for (var page = 0; page < index; page++) {
      offset +=
          pageColumns(page) * (pageCellSize(page) + SquareGridMetrics.gap);
    }
    return offset;
  }

  int pageColumns(int index) => pageEnd(index) - pageStarts[index];

  Iterable<GridItem> pageItems(int index) {
    final start = pageStarts[index];
    final end = pageEnd(index);
    return items.where((item) => item.x >= start && item.x < end);
  }

  double pageCellSize(int index) =>
      pageSizes[pageStarts[index]]?.cellSize ?? cellSize;
  int pageRows(int index) => pageItems(index).fold(
    pageSizes[pageStarts[index]]?.rows ?? configuredRows ?? defaultRows,
    (rows, item) => math.max(rows, item.y + item.h),
  );

  GridLayout pageLayout(int index) => GridLayout(
    pageItems(index).map((item) => item.copy(x: item.x - pageStarts[index])),
    columns: pageColumns(index),
    configuredRows: pageRows(index),
    cellSize: pageCellSize(index),
  );

  int get canvasColumns => math.max(columns, occupiedColumns);
  int pageEnd(int index) =>
      pageStarts.elementAtOrNull(index + 1) ?? canvasColumns;

  bool staysOnPage(GridItem item) =>
      !pageStarts.any((start) => item.x < start && item.x + item.w > start);

  bool get hasValidCanvas =>
      columns >= defaultColumns &&
      canvasColumns <= coordinateLimit &&
      rows <= coordinateLimit &&
      rows >= occupiedRows &&
      cellSize.isFinite &&
      cellSize >= SquareGridMetrics.minimumCell &&
      pageStarts.isNotEmpty &&
      pageStarts.first == 0 &&
      pageStarts.last < canvasColumns &&
      _orderedPages &&
      items.every(staysOnPage) &&
      pageSizes.entries.every(
        (entry) =>
            pageStarts.contains(entry.key) &&
            entry.value.rows >= 1 &&
            entry.value.rows <= coordinateLimit &&
            entry.value.cellSize.isFinite &&
            entry.value.cellSize >= SquareGridMetrics.minimumCell,
      );

  bool get _orderedPages {
    for (var index = 1; index < pageStarts.length; index++) {
      if (pageStarts[index] <= pageStarts[index - 1]) {
        return false;
      }
    }
    return true;
  }

  int get occupiedRows =>
      items.fold(1, (rows, item) => math.max(rows, item.y + item.h));
  int get occupiedColumns =>
      items.fold(1, (columns, item) => math.max(columns, item.x + item.w));
  int get rows => pageStarts.indexed.fold(
    1,
    (rows, page) => math.max(rows, pageRows(page.$1)),
  );

  GridLayout withItems(Iterable<GridItem> items) => GridLayout(
    items,
    columns: columns,
    configuredRows: configuredRows,
    cellSize: cellSize,
    pageStarts: pageStarts,
    pageSizes: pageSizes,
  );

  GridLayout withCanvas({
    required int columns,
    required int rows,
    double? cellSize,
    List<int>? pageStarts,
    Map<int, GridPageSize>? pageSizes,
  }) => GridLayout(
    items,
    columns: columns,
    configuredRows: rows,
    cellSize: cellSize ?? this.cellSize,
    pageStarts: pageStarts ?? this.pageStarts,
    pageSizes: pageSizes ?? this.pageSizes,
  );

  String encode() => jsonEncode({
    'version': 2,
    if (columns != defaultColumns) 'columns': columns,
    if (configuredRows != null) 'rows': configuredRows,
    if (cellSize != SquareGridMetrics.minimumCell) 'cellSize': cellSize,
    if (pageStarts.length > 1) 'pageStarts': pageStarts,
    if (pageSizes.isNotEmpty)
      'pageSizes': pageSizes.map(
        (anchor, size) => MapEntry('$anchor', size.toJson()),
      ),
    'items': items.map((item) => item.toJson()).toList(),
  });

  factory GridLayout.decode(String raw) {
    final value = jsonDecode(raw) as Map<String, dynamic>;
    if (value['version'] != 2) {
      throw const FormatException('Unsupported remote grid version.');
    }
    return GridLayout(
      (value['items'] as List<dynamic>).map(
        (item) => GridItem.fromJson(item as Map<String, dynamic>),
      ),
      columns: value['columns'] as int? ?? defaultColumns,
      configuredRows: value['rows'] as int?,
      cellSize:
          (value['cellSize'] as num?)?.toDouble() ??
          SquareGridMetrics.minimumCell,
      pageSizes:
          (value['pageSizes'] as Map<String, dynamic>?)?.map(
            (key, size) => MapEntry(
              int.parse(key),
              GridPageSize.fromJson(size as Map<String, dynamic>),
            ),
          ) ??
          const {},
      pageStarts:
          (value['pageStarts'] as List<dynamic>?)?.cast<int>() ?? const [0],
    );
  }
}
