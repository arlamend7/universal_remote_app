import 'package:flutter/material.dart';

import '../../layout/models/grid_layout.dart';
import '../../layout/models/square_grid_metrics.dart';
import 'grid_settings_sheet_state.dart';

class GridSettingsSheet extends StatefulWidget {
  const GridSettingsSheet({
    super.key,
    required this.layout,
    required this.metrics,
    required this.pageNumber,
  });

  final GridLayout layout;
  final int pageNumber;
  final SquareGridMetrics metrics;

  @override
  State<GridSettingsSheet> createState() => GridSettingsSheetState();
}
