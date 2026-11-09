import 'package:flutter/material.dart';

class DeviceSwipeActions extends StatelessWidget {
  const DeviceSwipeActions({
    super.key,
    required this.width,
    required this.onEdit,
    required this.onDelete,
  });

  final double width;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _action(
            'Edit',
            Icons.edit_outlined,
            colors.surfaceContainerHigh,
            colors.primary,
            onEdit,
          ),
          _action(
            'Delete',
            Icons.delete_outline,
            colors.errorContainer,
            colors.onErrorContainer,
            onDelete,
          ),
        ],
      ),
    );
  }

  Widget _action(
    String label,
    IconData icon,
    Color fill,
    Color foreground,
    VoidCallback onTap,
  ) => Expanded(
    child: Material(
      color: fill,
      child: InkWell(onTap: onTap, child: _label(label, icon, foreground)),
    ),
  );

  Widget _label(String label, IconData icon, Color foreground) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 2,
    children: [
      Icon(icon, color: foreground, size: 21),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: foreground, fontSize: 12),
      ),
    ],
  );
}
