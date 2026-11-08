import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';

/// A numeric [RemoteInput] shown as a slider that previews while dragging
/// and commits when released.
class SliderInput extends StatelessWidget {
  const SliderInput({
    super.key,
    required this.definition,
    required this.input,
    required this.item,
    required this.model,
    required this.axis,
  });
  final RemoteItemDefinition<Object> definition;
  final RemoteInput<Object, double> input;
  final GridItem item;
  final GridRemoteViewModel model;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final elementContext = model.elementContext(item);
    final reading = input.current!(elementContext);
    final current = reading != null && reading.isFinite ? reading : null;
    final bounds = input.bounds(elementContext);
    final span = bounds.maximum - bounds.minimum;
    if (!span.isFinite || span <= 0) {
      return const SizedBox.shrink();
    }
    final enabled =
        definition.isAvailableOn(model.remote) &&
        current != null &&
        model.canBindInput(input);
    final step = bounds.step;
    final divisions = step != null && step.isFinite && step > 0
        ? (span / step).clamp(1, 10000).round()
        : null;
    return RotatedBox(
      quarterTurns: axis == Axis.vertical ? 3 : 0,
      child: Slider(
        value: (current ?? bounds.minimum).clamp(
          bounds.minimum,
          bounds.maximum,
        ),
        min: bounds.minimum,
        divisions: divisions,
        max: bounds.maximum,
        label: current?.round().toString(),
        onChanged: enabled ? (value) => model.previewInput(input, value) : null,
        onChangeEnd: enabled ? _commit : null,
      ),
    );
  }

  void _commit(double value) {
    RemoteFeedback.commit();
    model.commitInput(input, value);
  }
}
