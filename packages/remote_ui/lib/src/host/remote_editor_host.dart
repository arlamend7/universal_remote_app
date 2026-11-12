import 'package:remote_core/remote_core.dart';

import '../editor/device_grids_controller.dart';
import 'remote_panel.dart';
import 'preview_remote_panel.dart';

/// Storage and device access supplied by the embedding application.
final class RemoteEditorHost {
  const RemoteEditorHost({
    required this.grids,
    required this.live,
    required this.canWakeDevice,
  });

  final DeviceGridsController grids;
  final RemotePanel live;
  final bool Function(RemoteDevice device) canWakeDevice;

  Set<RemoteCapability> capabilitiesFor(RemoteDevice device) {
    final profile =
        live.profiles.value.where((item) => item.id == device.id).firstOrNull ??
        device;
    return {
      ..._capabilities(profile)
          .where((capability) => capability != RemoteCapability.wake),
      if (canWakeDevice(profile)) RemoteCapability.wake,
    };
  }

  Set<RemoteCapability> _capabilities(RemoteDevice device) {
    final connection = live.connection;
    final controller = connection.controller;
    if (controller != null &&
        connection.selected.value?.id == device.id &&
        connection.state.value == DeviceConnectionState.connected) {
      return resolvedCapabilities(controller);
    }
    return device.metadata.containsKey(DeviceMetadataKeys.lastConnectedAt)
        ? device.capabilities
        : {};
  }

  RemotePanel preview(RemoteDevice device, {required bool sample}) =>
      PreviewRemotePanel(live, device, sample: sample);
}
