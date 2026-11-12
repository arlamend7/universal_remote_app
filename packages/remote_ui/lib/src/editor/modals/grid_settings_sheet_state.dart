import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../functions/default_remote_grid.dart';
import '../../layout/models/grid_layout.dart';
import '../../layout/models/square_grid_metrics.dart';
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

  bool _fitsControls(({int columns, int rows}) size) =>
      size.columns >= _minimumColumns &&
      size.rows >= widget.layout.occupiedRows;

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
        _presets(context),
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
        onPressed: _fitsControls(starterGridSize)
            ? () => _applyPreset(starterGridSize)
            : null,
        child: Text(
          'Reset (${starterGridSize.columns}×${starterGridSize.rows})',
        ),
      ),
    ),
  );

  Widget _presets(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 4,
    children: [
      Text('Grid presets', style: Theme.of(context).textTheme.titleSmall),
      Wrap(
        spacing: 8,
        children: [
          for (final size in remoteGridSizePresets)
            ChoiceChip(
              label: Text(
                size == starterGridSize
                    ? '${size.columns}×${size.rows} · Default'
                    : '${size.columns}×${size.rows}',
              ),
              selected: _columns == size.columns && _rows == size.rows,
              onSelected: _fitsControls(size)
                  ? (_) => _applyPreset(size)
                  : null,
            ),
        ],
      ),
    ],
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
          if (!_fitsControls(starterGridSize))
            const Text('Move controls inside the starter grid to reset.'),
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

  void _applyPreset(({int columns, int rows}) size) => setState(() {
    _columns = size.columns;
    _rows = size.rows;
    _cellSize = size == starterGridSize
        ? SquareGridMetrics.minimumCell
        : widget.metrics.cellSize(size.columns);
    _extraRows = math.max(0, _rows - _minimumRows);
    _error = null;
  });
}
