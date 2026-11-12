import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'scanning_dots.dart';

class ScanningDotsState extends State<ScanningDots>
    with SingleTickerProviderStateMixin {
  static const _count = 3;

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      return;
    }
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: _controller, builder: _dots);

  Widget _dots(BuildContext context, Widget? child) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: [for (var index = 0; index < _count; index++) _dot(index)],
  );

  Widget _dot(int index) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color.withValues(alpha: _opacity(index)),
        shape: BoxShape.circle,
      ),
    );
  }

  /// Each dot peaks one third of a cycle after the previous one.
  double _opacity(int index) {
    if (!_controller.isAnimating) {
      return 1;
    }
    final phase = (_controller.value - index / _count) * 2 * math.pi;
    return .35 + .65 * (math.cos(phase) + 1) / 2;
  }
}
