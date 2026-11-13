import 'package:flutter/material.dart';

import '../configuration/remote_item_style.dart';
import 'models/resize_candidate.dart';
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
    required this.resolveResize,
    this.minimumWidth = 1,
    this.minimumHeight = 1,
    this.style = const RemoteItemStyle(),
    this.enabled = true,
    this.selected = false,
  });

  final String id, label;
  final int width, height;

  /// The item's effective minimum; a drag never asks for less.
  final int minimumWidth, minimumHeight;
  final Widget child;
  final RemoteItemStyle style;
  final VoidCallback onEdit, onRemove;

  /// Commits the last valid footprint shown while resizing.
  final ValueChanged<ResizeCandidate> onResize;

  /// The nearest valid footprint for a requested size, or null.
  final ResizeCandidate? Function(int width, int height) resolveResize;
  final bool enabled, selected;
  @override
  State<UniversalRemoteItem> createState() => UniversalRemoteItemState();
}
