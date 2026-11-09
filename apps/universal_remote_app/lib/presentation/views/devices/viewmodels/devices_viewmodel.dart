import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import '../modals/edit_device.dart';
import '../../discovery/modals/show_device_discovery.dart';
import '../modals/show_device_details.dart';
import 'device_details_viewmodel.dart';

final class DevicesViewModel {
  DevicesViewModel(
    this.dependencies, {
    required this.onConnect,
    required this.onWake,
  });
  final AppDependencies dependencies;
  final void Function(RemoteDevice) onConnect;
  final void Function(RemoteDevice) onWake;
  Listenable get changes => Listenable.merge([
    dependencies.savedDevices.devices,
    dependencies.connection.state,
    dependencies.connection.selected,
    dependencies.connection.commandBusy,
  ]);
  List<RemoteDevice> get saved => dependencies.savedDevices.devices.value;
  Future<void> menu(
    BuildContext context,
    RemoteDevice device,
    String choice,
  ) async {
    final details = DeviceDetailsViewModel(dependencies, device);
    switch (choice) {
      case 'details':
        await showDeviceDetails(context, dependencies, device);
      case 'layout':
        await details.customize(context);
      case 'rename':
        await details.rename(context);
      case 'forget':
        await details.forget(context);
    }
  }

  Future<void> search(BuildContext context) async {
    final device = await showDeviceDiscovery(context, dependencies);
    if (device != null && context.mounted) {
      onConnect(device);
    }
  }

  int get connectedCount => saved.where(isConnected).length;

  DeviceConnectionState stateOf(RemoteDevice device) =>
      dependencies.connection.selected.value?.id == device.id
      ? dependencies.connection.state.value
      : DeviceConnectionState.disconnected;

  bool isConnected(RemoteDevice device) =>
      stateOf(device) == DeviceConnectionState.connected;

  bool canWake(RemoteDevice device) =>
      stateOf(device) == DeviceConnectionState.disconnected &&
      !dependencies.connection.commandBusy.value &&
      dependencies.providers.canWake(device);

  String? platformOf(RemoteDevice device) =>
      dependencies.providers.manualSetups[device.providerId]?.label ??
      device.manufacturer;
  Future<void> add(BuildContext context) async {
    final device = await editDevice(context, dependencies);
    if (device == null) {
      return;
    }
    onConnect(device);
  }

  Future<void> edit(
    BuildContext context,
    RemoteDevice device, {
    required bool saved,
  }) async {
    final edited = await editDevice(context, dependencies, device: device);
    if (edited == null) {
      return;
    }
    try {
      await _save(edited, saved);
      onConnect(edited);
    } catch (_) {
      _showError(context, 'Could not save protected device details.');
    }
  }

  Future<void> _save(RemoteDevice device, bool saved) async {
    if (!saved) {
      return;
    }
    await dependencies.savedDevices.save(device);
  }

  Future<void> forget(BuildContext context, RemoteDevice device) async {
    try {
      await dependencies.connection.forget(device);
    } catch (_) {
      _showError(context, 'Could not remove the protected device data.');
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
