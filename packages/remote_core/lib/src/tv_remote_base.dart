import 'package:remote_core/src/bluetooth_accessory.dart';
import 'package:remote_core/src/errors/remote_exception.dart';
import 'package:remote_core/src/remote_base.dart';

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

final class DeviceApplication {
  const DeviceApplication(this.id, this.name, {this.artwork});
  final String id;
  final String name;
  final Uri? artwork;
}

final class DeviceChannel {
  const DeviceChannel(this.id, this.name, this.number);
  final String id, name, number;
}

/// Only information actually reported by the device, never inferred playback.
final class CurrentContent {
  const CurrentContent({
    required this.appId,
    this.appName,
    this.channelName,
    this.channelNumber,
    this.liveTv = false,
    this.programTitle,
    this.position,
    this.duration,
  });
  final String appId;
  final String? appName;
  final String? channelName;
  final String? channelNumber;
  final bool liveTv;
  final String? programTitle;
  final Duration? position;
  final Duration? duration;

  /// Whether the integration reported live TV (tuner) content.
  bool get isLiveTv => liveTv;
}

final class DeviceInput {
  const DeviceInput(this.id, this.name);
  final String id;
  final String name;
}

enum MediaAction { play, pause, stop, rewind, fastForward, previous, next }

enum NavigationKey { up, down, left, right, enter, back, home }

enum RemoteKey {
  digit0('0'),
  digit1('1'),
  digit2('2'),
  digit3('3'),
  digit4('4'),
  digit5('5'),
  digit6('6'),
  digit7('7'),
  digit8('8'),
  digit9('9'),
  dash('DASH'),
  enter('ENTER'),
  menu('MENU'),
  info('INFO'),
  guide('GUIDE'),
  exit('EXIT'),
  red('RED'),
  green('GREEN'),
  yellow('YELLOW'),
  blue('BLUE'),
  source('SOURCE'),
  settings('MENU'),
  mute('MUTE'),
  replay('REPLAY'),
  liveTv('LIVE_TV'),
  captions('CAPTIONS');

  const RemoteKey(this.wireName);
  final String wireName;
}

final class VolumeState {
  const VolumeState(this.volume, this.muted);
  final int volume;

  /// Null when the device reports volume without exposing mute feedback.
  final bool? muted;
}
