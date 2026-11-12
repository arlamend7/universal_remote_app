import 'package:flutter/material.dart';

import 'scanner_pulse.dart';

class ScannerPulseState extends State<ScannerPulse>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = .5;
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
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: AnimatedBuilder(animation: _controller, builder: _pulse),
  );

  Widget _pulse(BuildContext context, Widget? child) {
    final color = Theme.of(context).colorScheme.primary;
    final progress = Curves.easeOut.transform(_controller.value);
    return Stack(
      alignment: Alignment.center,
      children: [
        _circle(color.withValues(alpha: .28 * (1 - progress)), progress),
        _circle(color.withValues(alpha: .22), .62),
        _circle(color, .36),
      ],
    );
  }

  Widget _circle(Color color, double scale) => Container(
    width: widget.size * scale,
    height: widget.size * scale,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
