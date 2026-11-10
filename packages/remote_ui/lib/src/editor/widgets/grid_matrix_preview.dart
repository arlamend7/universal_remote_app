import 'package:flutter/material.dart';

import '../../layout/models/grid_layout.dart';
import 'grid_matrix_painter.dart';

class GridMatrixPreview extends StatelessWidget {
  const GridMatrixPreview({
    super.key,
    required this.layout,
    required this.columns,
    required this.rows,
  });

  final GridLayout layout;
  final int columns, rows;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        spacing: 8,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Matrix Preview')),
              Text('$columns × $rows'),
            ],
          ),
          CustomPaint(
            size: const Size(168, 120),
            painter: GridMatrixPainter(
              layout: layout,
              columns: columns,
              rows: rows,
              colors: Theme.of(context).colorScheme,
            ),
          ),
        ],
      ),
    ),
  );
}
