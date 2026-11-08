import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import 'grid_button.dart';
import 'grid_unavailable.dart';

class GridClimateWidget extends StatelessWidget {
  const GridClimateWidget({super.key, required this.model});
  final GridRemoteViewModel model;

  @override
  Widget build(BuildContext context) {
    final device = model.remote.connection.controller;
    if (device is! AcDeviceController ||
        model.remote.device?.id != device.device.id ||
        model.previewData != null) {
      return _unavailable();
    }
    final range = device.targetTemperatureRange;
    if (!device.supports(RemoteCapability.climate) ||
        range == null ||
        range.step <= 0) {
      return _unavailable();
    }
    return StreamBuilder<double?>(
      key: ObjectKey(device),
      stream: device.targetTemperatureChanges,
      initialData: device.targetTemperature,
      builder: (_, snapshot) => _controls(device, snapshot.data, range),
    );
  }

  Widget _controls(
    AcDeviceController device,
    double? value,
    ({double minimum, double maximum, double step}) range,
  ) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Flexible(child: _step(device, value, -range.step, range.minimum)),
      Text(value == null ? '—' : '${value.toStringAsFixed(1)}°C'),
      Flexible(child: _step(device, value, range.step, range.maximum)),
    ],
  );

  Widget _step(
    AcDeviceController device,
    double? value,
    double delta,
    double limit,
  ) {
    final increasing = delta > 0;
    final proposed = value == null ? null : value + delta;
    final enabled =
        model.ready &&
        proposed != null &&
        (increasing ? proposed <= limit : proposed >= limit);
    return GridButton(
      label: increasing ? 'Warmer' : 'Cooler',
      icon: increasing ? Icons.add : Icons.remove,
      showLabel: false,
      onPressed: enabled
          ? () => model.execute(
              () =>
                  RemoteItemRegistry.resolve(GridWidgetKind.targetTemperature)
                      .element(AcItems.targetTemperature)
                      .commit(device, proposed),
            )
          : null,
    );
  }

  Widget _unavailable() => const GridUnavailable(
    title: 'Target temperature',
    reason: 'Available when an air conditioner reports a temperature range.',
  );
}
