import 'package:flutter/material.dart' show Icons;
import 'package:remote_core/remote_core.dart';

import '../layout/models/enums/grid_widget_kind.dart';
import '../elements/remote_input.dart';
import '../definitions/enums/remote_item_category.dart';
import '../definitions/remote_item_definition.dart';

abstract final class AcItems {
  static final definitions = <RemoteItemDefinition<ACRemoteBase>>[
    RemoteItemDefinition(
      GridWidgetKind.targetTemperature,
      'Target temperature',
      RemoteItemCategory.climate,
      description: 'Adjust the air conditioner target temperature in Celsius.',
      requires: const {RemoteCapability.climate},
      elements: [targetTemperature],
    ),
  ];

  static final targetTemperature = RemoteInput<AcDeviceController, double>(
    'target_temperature',
    icon: (_) => Icons.thermostat,
    commit: (device, value) async {
      if (!device.supports(RemoteCapability.climate)) {
        throw const RemoteException(
          'climate',
          'Temperature control is unavailable.',
        );
      }
      final range = device.targetTemperatureRange;
      if (range == null ||
          !value.isFinite ||
          value < range.minimum ||
          value > range.maximum) {
        throw const RemoteException(
          'temperature',
          'The target temperature is outside the reported range.',
        );
      }
      await device.setTargetTemperature(value);
    },
  );
}
