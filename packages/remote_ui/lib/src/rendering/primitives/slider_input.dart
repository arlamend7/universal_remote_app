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

  RemoteInput<TvRemoteDevice, double> get _tv =>
      input as RemoteInput<TvRemoteDevice, double>;

  @override
  Widget build(BuildContext context) {
    final current = input.current!(model.elementContext(item));
    final enabled = definition.isAvailableOn(model.remote) && current != null;
    return RotatedBox(
      quarterTurns: axis == Axis.vertical ? 3 : 0,
      child: Slider(
        value: (current ?? 0).clamp(0, input.maximum),
        max: input.maximum,
        label: current?.round().toString(),
        semanticFormatterCallback: (value) => '${value.round()} percent',
        onChanged: enabled ? (value) => _tv.preview?.call(model, value) : null,
        onChangeEnd: enabled ? _commit : null,
      ),
    );
  }

  void _commit(double value) {
    RemoteFeedback.commit();
    _tv.commit(model, value);
  }
}
