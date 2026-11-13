import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/src/ui_model.dart';

import 'grid_item_preview.dart';
import 'preview_dots_painter.dart';

class ControlDraftPreview extends StatelessWidget {
  const ControlDraftPreview({
    super.key,
    required this.item,
    required this.dependencies,
    required this.device,
    required this.height,
  });

  final GridItem item;
  final RemoteEditorHost dependencies;
  final RemoteDevice device;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: PreviewDotsPainter(
          Theme.of(context).colorScheme.outlineVariant,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: FittedBox(fit: BoxFit.contain, child: _control(context)),
        ),
      ),
    ),
  );

  Widget _control(BuildContext context) => SizedBox(
    width: item.w * 80.0,
    height: item.h * 80.0,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(item.style.cornerRadius),
      ),
      child: _styledControl(),
    ),
  );

  Widget _styledControl() => StyledItem(
    style: item.style,
    child: GridItemPreview(
      item: item,
      dependencies: dependencies,
      device: device,
      sample: true,
      sampleAppTargets: false,
    ),
  );
}
