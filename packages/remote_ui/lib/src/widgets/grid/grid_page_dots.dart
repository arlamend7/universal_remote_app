import 'package:flutter/material.dart';

class GridPageDots extends StatelessWidget {
  const GridPageDots({
    super.key,
    required this.count,
    required this.selected,
    required this.onSelected,
    this.swipe = true,
    this.leading,
    this.trailing,
  });

  static const _tapSize = 44.0;

  static double heightFor({required int count, required double width}) {
    if (count < 2) {
      return 0;
    }
    final columns = ((width - 36) / _tapSize).floor().clamp(1, count);
    return (count / columns).ceil() * _tapSize + 8;
  }

  final int count, selected;
  final bool swipe;
  final Widget? leading, trailing;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?leading,
            Flexible(child: _dots(context)),
            ?trailing,
          ],
        ),
      ),
    ),
  );

  Widget _dots(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onHorizontalDragEnd: !swipe || count < 2
        ? null
        : (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity != 0) {
              final forward =
                  (velocity < 0) ==
                  (Directionality.of(context) == TextDirection.ltr);
              onSelected((selected + (forward ? 1 : -1)).clamp(0, count - 1));
            }
          },
    child: Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (var index = 0; index < count; index++) _dot(context, index),
      ],
    ),
  );

  Widget _dot(BuildContext context, int index) {
    final accent = Theme.of(context).colorScheme.primary;
    final active = index == selected;
    return Semantics(
      selected: active,
      child: SizedBox.square(
        dimension: _tapSize,
        child: IconButton(
          tooltip: 'Page ${index + 1} of $count',
          onPressed: () => onSelected(index),
          icon: Container(
            width: active ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: active ? 1 : .35),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
