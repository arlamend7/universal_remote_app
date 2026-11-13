import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import '../../discovery/pages/show_device_discovery.dart';
import '../modals/show_device_details.dart';

import 'package:remote_ui/remote_ui.dart';

import 'device_details_viewmodel.dart';

final class DevicesViewModel {
  DevicesViewModel(
    this.dependencies, {
    required this.onConnect,
    required this.onWake,
    required this.onCustomize,
  });
  final AppDependencies dependencies;
  final void Function(RemoteDevice) onConnect;
  final void Function(RemoteDevice) onWake;
  final Future<void> Function(BuildContext, RemoteDevice) onCustomize;
  Listenable get changes => Listenable.merge([
    dependencies.savedDevices.devices,
    dependencies.connection.state,
    dependencies.connection.selected,
    dependencies.connection.commandBusy,
    dependencies.discovery.recentDevices,
  ]);
  List<RemoteDevice> get saved => dependencies.savedDevices.devices.value;
  Future<void> info(BuildContext context, RemoteDevice device) async {
    final customize = await showDeviceDetails(context, dependencies, device);
    if (customize && context.mounted) {
      await onCustomize(context, device);
    }
  }

  Future<void> search(BuildContext context) async {
    final device = await showDeviceDiscovery(context, dependencies);
    if (device != null && context.mounted) {
      onConnect(device);
    }
  }

  int get connectedCount => saved.where(isConnected).length;

  DeviceConnectionState stateOf(RemoteDevice device) {
    final selected = dependencies.connection.selected.value?.id;
    final sameDevice =
        selected == device.id ||
        dependencies.savedDevices
                .logicalDevice(device.id)
                ?.profiles
                .any((profile) => profile.id == selected) ==
            true;
    return sameDevice
        ? dependencies.connection.state.value
        : DeviceConnectionState.disconnected;
  }

  bool isConnected(RemoteDevice device) =>
      stateOf(device) == DeviceConnectionState.connected;

  bool canWake(RemoteDevice device) =>
      stateOf(device) == DeviceConnectionState.disconnected &&
      !dependencies.connection.commandBusy.value &&
      dependencies.providers.canWake(device);

  bool possiblyAwake(RemoteDevice device) {
    if (!dependencies.providers.canWake(device)) {
      return false;
    }
    const resolver = DeviceIdentifierResolver();
    final logical = dependencies.savedDevices.logicalDevice(device.id);
    final profiles =
        logical?.profiles.map((profile) => profile.device) ?? [device];
    return dependencies.discovery.recentDevices.value.any(
      (found) => profiles.any((profile) => resolver.same(profile, found)),
    );
  }

  String? platformOf(RemoteDevice device) =>
      dependencies.providers.manualSetups[device.providerId]?.label ??
      device.manufacturer;
  Future<void> edit(BuildContext context, RemoteDevice device) =>
      DeviceDetailsViewModel(dependencies, device).edit(context);

  Future<void> forget(BuildContext context, RemoteDevice device) async {
    final confirmed = await ConfirmationDialog.ask(
      context,
      title: 'Delete ${device.name}?',
      confirmLabel: 'Delete',
      message:
          'Removes this device, its saved layouts and pairing credentials.',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await dependencies.connection.forget(device);
    } catch (_) {
      _showError(
        context,
        'Could not remove the saved device data. Please retry.',
      );
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
