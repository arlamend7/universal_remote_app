import 'package:flutter/material.dart';

import '../configuration/remote_item_style.dart';
import 'universal_remote_item_state.dart';

/// Shared item shell. Edit mode adds selection and manipulation affordances.
class UniversalRemoteItem extends StatefulWidget {
  const UniversalRemoteItem({
    super.key,
    required this.id,
    required this.label,
    required this.width,
    required this.height,
    required this.child,
    required this.onEdit,
    required this.onRemove,
    required this.onResize,
    this.canResize,
    this.minimumWidth = 1,
    this.minimumHeight = 1,
    this.maximumWidth = 8,
    this.maximumHeight = 16,
    this.style = const RemoteItemStyle(),
    this.enabled = true,
    this.selected = false,
  });

  final String id, label;
  final int width, height;

  /// Resizing stops at these bounds: the definition's fixed minimum and the
  /// room left on the page.
  final int minimumWidth, minimumHeight, maximumWidth, maximumHeight;
  final Widget child;
  final RemoteItemStyle style;
  final VoidCallback onEdit, onRemove;
  final void Function(int width, int height) onResize;
  final bool Function(int width, int height)? canResize;
  final bool enabled, selected;
  @override
  State<UniversalRemoteItem> createState() => UniversalRemoteItemState();
}
