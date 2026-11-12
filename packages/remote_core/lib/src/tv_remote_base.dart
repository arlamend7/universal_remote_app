import 'capabilities/enums/remote_key.dart';
import 'capabilities/enums/navigation_key.dart';
import 'capabilities/enums/media_action.dart';
import 'devices/models/volume_state.dart';
import 'devices/models/device_input.dart';
import 'devices/models/current_content.dart';
import 'devices/models/device_channel.dart';
import 'devices/models/device_application.dart';

import 'package:remote_core/src/bluetooth_accessory.dart';
import 'package:remote_core/src/errors/remote_exception.dart';
import 'package:remote_core/src/remote_base.dart';

export 'capabilities/enums/remote_key.dart';
export 'capabilities/enums/navigation_key.dart';
export 'capabilities/enums/media_action.dart';
export 'devices/models/device_application.dart';
export 'devices/models/device_channel.dart';
export 'devices/models/current_content.dart';
export 'devices/models/device_input.dart';
export 'devices/models/volume_state.dart';

/// Television commands. Providers throw [RemoteException] for any command the
/// connected device does not support; [supports] reports driver evidence.
abstract class TVRemoteBase extends RemoteBase {
  Future<void> volumeUp();
  Future<void> volumeDown();
  Future<void> setVolume(int volume);
  Future<void> setMuted(bool muted);

  /// Flips mute. Providers that only have a mute key send it; the state may be
  /// unknown ([VolumeState.muted] null).
  Future<void> toggleMute() => _unsupported('Mute');
  Future<VolumeState> readVolume();
  Stream<VolumeState> watchVolume();

  Future<void> press(NavigationKey key);

  Future<void> channelUp();
  Future<void> channelDown();
  Future<List<DeviceChannel>> channels();
  Future<void> selectChannel(String id);

  Future<void> sendMedia(MediaAction action);
  Future<void> togglePlayback() => _unsupported('Play/Pause');

  /// Whether the device reports media as playing (true), paused (false) or
  /// does not say (null).
  Future<bool?> playbackState() async => null;

  /// Turns the picture off while the TV keeps running, and back on.
  Future<void> turnOffScreen() => _unsupported('Screen off');
  Future<void> turnOnScreen() => _unsupported('Screen on');

  Future<void> movePointer(double dx, double dy);
  Future<void> scroll(double dx, double dy);
  Future<void> click();
  Future<void> sendKey(RemoteKey key);

  Future<void> sendText(String text);
  Future<void> sendEnter();

  Future<List<DeviceInput>> inputs();
  Future<void> selectInput(String id);

  /// Opens the TV's own input picker, for TVs that cannot list their inputs
  /// ([inputs] returns empty).
  Future<void> openInputPicker() => _unsupported('Input picker');
  DeviceInput? get currentInput => null;
  Stream<DeviceInput?> get currentInputChanges => const Stream.empty();

  Future<List<DeviceApplication>> applications();

  /// Launches an app by id; providers that launch by link accept a link too,
  /// and may report no list ([applications] empty).
  Future<void> launchApplication(String id);
  Future<String?> currentApplication();

  /// Ids from the latest successful app-list response, or null when unknown.
  Set<String>? get reportedApplicationIds => null;

  Future<CurrentContent> currentContent();
  Stream<CurrentContent> watchCurrentContent();

  Future<List<BluetoothAccessory>> bluetoothAccessories() =>
      _unsupported('Bluetooth accessories');
  Future<void> toggleBluetoothAccessory(String id) =>
      _unsupported('Bluetooth accessory connection');

  /// Opens the TV's settings so the user can manage accessories on screen.
  Future<void> openAccessorySettings() => _unsupported('Accessory settings');

  Future<void> startVoiceControl() => _unsupported('Voice control');
  Future<void> toggleGameMode() => _unsupported('Game mode');
  Future<void> syncWatchCompanion() => _unsupported('Watch companion');
}

Future<Never> _unsupported(String feature) => Future.error(
  RemoteException('unsupported', '$feature is not supported by this device.'),
);
