import 'package:remote_core/remote_core.dart';

import '../../commands/services/lg_command_channel.dart';
import '../../connection/functions/lg_connection_error.dart';
import '../../connection/models/lg_connection_options.dart';
import '../../pointer/services/lg_pointer_connection.dart';
import '../../protocol/services/ssap_client.dart';
import '../accessories/lg_bluetooth_accessory_controller.dart';
import '../applications/lg_application_controller.dart';
import '../inputs/lg_input_controller.dart';
import '../power/lg_power_controller.dart';
import '../volume/lg_volume_controller.dart';
import '../content/lg_current_content_controller.dart';
import 'lg_capability_registry.dart';
import '../text/lg_text_controller.dart';
import '../channels/lg_channel_selection_controller.dart';

final class LgCapabilityResolver {
  LgCapabilityResolver({
    required this.commands,
    required this.pointer,
    required this.registry,
    required this.client,
    required this.endpoint,
    required this.options,
    required this.isCurrent,
  });
  final LgCommandChannel commands;
  final LgPointerConnection pointer;
  final LgCapabilityRegistry registry;
  final SsapClient client;
  final Uri endpoint;
  final LgConnectionOptions options;
  final bool Function() isCurrent;
  Future<void> resolve() async {
    await Future.wait([
      _volume(),
      _applications(),
      _inputs(),
      _navigation(),
      _bluetooth(),
    ]);
    if (!isCurrent()) {
      return;
    }
    registry.enable(
      RemoteCapability.currentContent,
      LgCurrentContentController(commands),
      CapabilityAvailability.known,
    );
    registry.enable(
      RemoteCapability.channels,
      commands,
      CapabilityAvailability.known,
    );
    registry.enable(
      RemoteCapability.media,
      commands,
      CapabilityAvailability.known,
    );
    registry.enable(
      RemoteCapability.textInput,
      LgTextController(commands),
      CapabilityAvailability.known,
    );
    registry.enable(
      RemoteCapability.channelSelection,
      LgChannelSelectionController(commands),
      CapabilityAvailability.known,
    );
    // A power-off probe would be destructive; keep its evidence driver-known.
    registry.enable(
      RemoteCapability.power,
      LgPowerController(commands, options),
      CapabilityAvailability.known,
    );
  }

  Future<void> _volume() async {
    final controller = LgVolumeController(commands);
    try {
      await controller.readVolume();
      _volumeCommands(controller);
      if (isCurrent()) {
        registry.enable(
          RemoteCapability.volumeFeedback,
          controller,
          CapabilityAvailability.verified,
        );
      }
    } catch (error) {
      _volumeWithoutFeedback(controller, error);
    }
  }

  void _volumeWithoutFeedback(LgVolumeController controller, Object error) {
    if (!isCurrent()) {
      return;
    }
    _volumeCommands(controller);
    _unavailable(RemoteCapability.volumeFeedback, error);
  }

  void _volumeCommands(LgVolumeController controller) {
    if (!isCurrent()) {
      return;
    }
    for (final capability in [
      RemoteCapability.volume,
      RemoteCapability.absoluteVolume,
      RemoteCapability.mute,
    ]) {
      registry.enable(capability, controller, CapabilityAvailability.known);
    }
  }

  Future<void> _applications() async {
    final controller = LgApplicationController(commands);
    await _probe(
      RemoteCapability.applications,
      controller,
      () async => _nonEmpty(await controller.applications()),
    );
    if (!isCurrent() || !controller.hasSettings) {
      return;
    }
    registry.enable(
      RemoteCapability.accessorySettings,
      controller,
      CapabilityAvailability.known,
    );
  }

  Future<void> _bluetooth() {
    final controller = LgBluetoothAccessoryController(commands);
    return _probe(
      RemoteCapability.bluetoothAccessories,
      controller,
      () => controller.pairedDevices(timeout: const Duration(seconds: 2)),
    );
  }

  Future<void> _inputs() async {
    final controller = LgInputController(commands);
    await _probe(
      RemoteCapability.inputs,
      controller,
      () async => _nonEmpty(await controller.inputs()),
    );
  }

  void _nonEmpty(List<Object> entries) {
    if (entries.isEmpty) {
      throw const RemoteException('unavailable', 'The TV returned no entries.');
    }
  }

  Future<void> _navigation() =>
      _probe(RemoteCapability.navigation, pointer, _openPointer);
  Future<void> _openPointer() async {
    final response = await client.request(
      'com.webos.service.networkinput/getPointerInputSocket',
    );
    if (!isCurrent()) {
      return;
    }
    await pointer.open(response['socketPath'], endpoint, options);
    if (isCurrent()) {
      registry.enable(
        RemoteCapability.pointer,
        pointer,
        CapabilityAvailability.known,
      );
    }
  }

  Future<void> _probe(
    RemoteCapability kind,
    Object controller,
    Future<Object?> Function() action,
  ) async {
    try {
      await action();
      _known(kind, controller);
    } catch (error) {
      _unavailable(kind, error);
    }
  }

  void _known(RemoteCapability kind, Object controller) {
    if (!isCurrent()) {
      return;
    }
    registry.enable(kind, controller, CapabilityAvailability.known);
  }

  void _unavailable(RemoteCapability kind, Object error) {
    if (!isCurrent()) {
      return;
    }
    registry.disable(kind, reason: lgConnectionError(error).message);
  }
}
