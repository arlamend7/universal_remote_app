import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';

/// The operation set each capability needs before it can enable a control.
abstract final class DriverTvCapabilities {
  static final Map<RemoteCapability, List<String>> _required = {
    RemoteCapability.volume: ['volume-up', 'volume-down'],
    RemoteCapability.volumeFeedback: ['read-volume'],
    RemoteCapability.absoluteVolume: ['set-volume'],
    RemoteCapability.mute: ['toggle-mute'],
    RemoteCapability.navigation: [
      for (final key in NavigationKey.values) 'navigation-${key.name}',
    ],
    RemoteCapability.pointer: [
      'pointer-move',
      'pointer-scroll',
      'pointer-click',
    ],
    RemoteCapability.channels: ['channel-up', 'channel-down'],
    RemoteCapability.channelCatalog: ['list-channels'],
    RemoteCapability.channelSelection: ['list-channels', 'select-channel'],
    RemoteCapability.media: ['media-play', 'media-pause', 'media-stop'],
    RemoteCapability.trackNavigation: ['media-next', 'media-previous'],
    RemoteCapability.playbackScan: ['media-rewind', 'media-fast-forward'],
    RemoteCapability.playbackToggle: ['toggle-playback'],
    RemoteCapability.applications: ['launch-application'],
    RemoteCapability.inputs: ['open-input-picker'],
    RemoteCapability.currentInput: ['read-input'],
    RemoteCapability.currentContent: ['read-content'],
    RemoteCapability.textInput: ['send-text', 'send-enter'],
    RemoteCapability.power: ['power-off'],
    RemoteCapability.screenPower: ['screen-off', 'screen-on'],
    RemoteCapability.wake: ['wake'],
    RemoteCapability.accessorySettings: ['open-accessory-settings'],
    RemoteCapability.bluetoothAccessories: [
      'list-accessories',
      'toggle-accessory',
    ],
    RemoteCapability.tvSettings: ['key-settings'],
    RemoteCapability.liveTvKey: ['key-live-tv'],
    RemoteCapability.captionsKey: ['key-captions'],
    RemoteCapability.instantReplay: ['key-replay'],
    RemoteCapability.numericKeys: [
      for (var digit = 0; digit < 10; digit++) 'key-digit$digit',
    ],
    RemoteCapability.specialKeys: ['key-menu', 'key-info', 'key-guide'],
  };

  static bool provides(
    DriverBundle bundle,
    RemoteCapability capability,
    String action,
  ) =>
      bundle.capabilities[capability]?.contains(action) == true &&
      bundle.commands.containsKey(action);

  static bool supports(DriverBundle bundle, RemoteCapability capability) {
    if (capability == RemoteCapability.inputs) {
      return provides(bundle, capability, 'open-input-picker') ||
          [
            'list-inputs',
            'select-input',
          ].every((action) => provides(bundle, capability, action));
    }
    if (capability == RemoteCapability.mute &&
        provides(bundle, capability, 'set-mute') &&
        provides(bundle, RemoteCapability.volumeFeedback, 'read-volume')) {
      return true;
    }
    final required = _required[capability];
    return required != null &&
        required.every((action) => provides(bundle, capability, action));
  }
}
