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
    this.quarterTurns = 0,
    this.style = const RemoteItemStyle(),
    this.enabled = true,
    this.selected = false,
  });
  const UniversalRemoteItem.control({
    super.key,
    required this.child,
    this.quarterTurns = 0,
    this.style = const RemoteItemStyle(),
  }) : id = '',
       label = '',
       width = 1,
       height = 1,
       onEdit = null,
       onRemove = null,
       onResize = null,
       enabled = true,
       selected = false;

  final String id, label;
  final int width, height, quarterTurns;
  final Widget child;
  final RemoteItemStyle style;
  final VoidCallback? onEdit, onRemove;
  final void Function(int width, int height)? onResize;
  final bool enabled, selected;
  @override
  State<UniversalRemoteItem> createState() => UniversalRemoteItemState();
}
