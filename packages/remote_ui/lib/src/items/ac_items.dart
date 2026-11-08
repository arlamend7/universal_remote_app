import 'package:flutter/material.dart' show Icons;
import 'package:remote_core/remote_core.dart';

import '../elements/remote_action.dart';
import '../elements/remote_element_context.dart';
import '../elements/remote_info.dart';
import '../elements/remote_input.dart';
import '../elements/remote_reading.dart';
import '../definitions/enums/remote_item_category.dart';
import '../definitions/layouts/layouts.dart';
import '../definitions/remote_item_definition.dart';

abstract final class AcItems {
  static final definitions = <RemoteItemDefinition<ACRemoteBase>>[
    RemoteItemDefinition(
      'targetTemperature',
      'Target temperature',
      RemoteItemCategory.climate,
      layout: LinearLayout(size: RemoteItemSize(4, 1, minimumWidth: 2)),
      description: 'Adjust the air conditioner target temperature in Celsius.',
      requires: const {RemoteCapability.climate},
      elements: [cooler, temperature, warmer],
    ),
  ];

  /// The connected air conditioner when it is the device this panel shows.
  static ACRemoteBase? _device(RemoteElementContext context) {
    final device = context.remote.connection.controller;
    if (device is! ACRemoteBase ||
        context.remote.device?.id != device.device.id) {
      return null;
    }
    return device;
  }

  static double? _proposed(ACRemoteBase? device, double direction) {
    final range = device?.targetTemperatureRange;
    final value = device?.targetTemperature;
    if (device == null || range == null || range.step <= 0 || value == null) {
      return null;
    }
    final proposed = value + direction * range.step;
    return proposed < range.minimum || proposed > range.maximum
        ? null
        : proposed;
  }

  static final cooler = RemoteAction<ACRemoteBase>(
    'cooler',
    showLabel: false,
    builder: (context, device) => (
      icon: Icons.remove,
      label: 'Cooler',
      enabled: _proposed(device, -1) != null,
      execute: () => _step(device, -1),
    ),
  );
  static final warmer = RemoteAction<ACRemoteBase>(
    'warmer',
    showLabel: false,
    builder: (context, device) => (
      icon: Icons.add,
      label: 'Warmer',
      enabled: _proposed(device, 1) != null,
      execute: () => _step(device, 1),
    ),
  );

  static Future<void> _step(ACRemoteBase device, double direction) async {
    final proposed = _proposed(device, direction);
    if (proposed != null) {
      await targetTemperature.commit(device, proposed);
    }
  }

  static String _format(double? value) =>
      value == null ? '—' : '${value.toStringAsFixed(1)}°C';
  static final temperature = RemoteInfo<ACRemoteBase>(
    'target_temperature_reading',
    icon: (_) => Icons.thermostat,
    watch: (context) =>
        _device(context)?.targetTemperatureChanges
            .map((value) => RemoteReading(_format(value))),
    read: (context) =>
        RemoteReading(_format(_device(context)?.targetTemperature)),
  );

  static final targetTemperature = RemoteInput<ACRemoteBase, double>(
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
