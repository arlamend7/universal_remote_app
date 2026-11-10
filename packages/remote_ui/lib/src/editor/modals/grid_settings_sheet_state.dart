import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../layout/models/grid_layout.dart';
import '../../widgets/sheets/app_sheet.dart';
import '../../widgets/sheets/app_sheet_actions.dart';
import '../widgets/editor_number_field.dart';
import '../widgets/grid_matrix_preview.dart';
import 'grid_settings_sheet.dart';

class GridSettingsSheetState extends State<GridSettingsSheet> {
  late int _columns = widget.layout.columns;
  late int _rows = widget.layout.rows;
  late double _cellSize = widget.layout.cellSize;
  late int _extraRows = widget.layout.configuredRows == null
      ? 0
      : math.max(0, _rows - _minimumRows);
  String? _error;

  int get _minimumColumns => math.max(
    math.max(GridLayout.defaultColumns, widget.layout.pageStarts.last + 1),
    widget.layout.occupiedColumns,
  );

  int get _maximumColumns =>
      math.max(GridLayout.maxColumns, widget.layout.columns);

  int get _fittingRows => widget.metrics
      .fittingRows(_cellSize)
      .clamp(1, GridLayout.coordinateLimit);

  int get _minimumRows => math.max(_fittingRows, widget.layout.occupiedRows);

  bool get _canReset =>
      widget.layout.pageStarts.length == 1 &&
      widget.layout.occupiedColumns <= GridLayout.defaultColumns &&
      widget.layout.occupiedRows <= GridLayout.defaultRows;

  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'Grid Settings',
    subtitle: 'Page ${widget.pageNumber}',
    horizontalInset: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        GridMatrixPreview(
          layout: widget.layout,
          columns: _columns,
          rows: _rows,
        ),
        _dimensions(),
        if (_error != null) Text(_error!),
      ],
    ),
    footer: AppSheetActions(
      primary: FilledButton.icon(
        onPressed: () => Navigator.pop(context, (
          columns: _columns,
          rows: _rows,
          cellSize: _cellSize,
        )),
        icon: const Icon(Icons.check),
        label: const Text('Apply Grid'),
      ),
      secondary: OutlinedButton(
        onPressed: _canReset ? _reset : null,
        child: const Text('Reset (4×8)'),
      ),
    ),
  );

  Widget _dimensions() => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text('Dimensions', style: Theme.of(context).textTheme.titleMedium),
          EditorNumberField(
            label: 'Width',
            value: _columns,
            minimum: _minimumColumns,
            maximum: _maximumColumns,
            onChanged: _changeWidth,
          ),
          const Divider(),
          EditorNumberField(
            label: 'Height',
            value: _rows,
            minimum: math.min(_rows, _minimumRows),
            maximum: GridLayout.coordinateLimit,
            onChanged: _changeHeight,
          ),
          Text('${_fittingRows} rows fit without scrolling.'),
          if (_columns > widget.metrics.fittingColumns)
            const Text('Swipe sideways to see all columns on this screen.'),
          if (!_canReset)
            const Text('Move controls inside the 4×8 area to reset.'),
        ],
      ),
    ),
  );

  void _changeWidth(int value) {
    if (value < _minimumColumns ||
        (value > _maximumColumns && value >= _columns)) {
      setState(
        () =>
            _error = 'Choose a width that keeps all controls within the grid.',
      );
      return;
    }
    if (value == _columns) {
      return;
    }
    setState(() {
      _cellSize = widget.metrics.cellSize(value);
      final rows = _minimumRows + _extraRows;
      _columns = value;
      _rows = math.min(rows, GridLayout.coordinateLimit);
      _error = null;
    });
  }

  void _changeHeight(int value) {
    if (value < math.min(_rows, _minimumRows) ||
        value > GridLayout.coordinateLimit) {
      setState(
        () => _error =
            'Choose a height that keeps all occupied and visible rows.',
      );
      return;
    }
    setState(() {
      _rows = value;
      _extraRows = math.max(0, value - _minimumRows);
      _error = null;
    });
  }

  void _reset() => setState(() {
    _columns = GridLayout.defaultColumns;
    _rows = GridLayout.defaultRows;
    _extraRows = 0;
    _cellSize = widget.metrics.cellSize(_columns);
    _error = null;
  });
}
