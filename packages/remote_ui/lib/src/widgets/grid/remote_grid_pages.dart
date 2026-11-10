import 'package:flutter/material.dart';

import '../../layout/models/grid_item.dart';
import '../../layout/models/grid_layout.dart';
import 'remote_grid_pages_state.dart';

class RemoteGridPages extends StatefulWidget {
  const RemoteGridPages({
    super.key,
    required this.layout,
    required this.itemBuilder,
    required this.swipeOnCanvas,
    this.initialPage = 0,
    this.onPageChanged,
    this.ownsDragGesture,
  });

  final GridLayout layout;
  final bool swipeOnCanvas;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;
  final bool Function(GridItem)? ownsDragGesture;
  final Widget Function(GridItem) itemBuilder;

  @override
  State<RemoteGridPages> createState() => RemoteGridPagesState();
}
