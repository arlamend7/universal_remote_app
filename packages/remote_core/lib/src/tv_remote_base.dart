import 'package:remote_core/src/errors/remote_exception.dart';
import 'package:remote_core/src/remote_base.dart';

/// Television commands. Providers throw [RemoteException] for any command the
/// connected device does not support; [supports] reports driver evidence.
abstract class TVRemoteBase extends RemoteBase {
  Future<void> volumeUp();
  Future<void> volumeDown();
  Future<void> setVolume(int volume);
  Future<void> setMuted(bool muted);
  Future<VolumeState> readVolume();
  Stream<VolumeState> watchVolume();

  Future<void> press(NavigationKey key);

  Future<void> channelUp();
  Future<void> channelDown();
  Future<List<DeviceChannel>> channels();
  Future<void> selectChannel(String id);

  Future<void> sendMedia(MediaAction action);

  Future<void> movePointer(double dx, double dy);
  Future<void> scroll(double dx, double dy);
  Future<void> click();
  Future<void> sendKey(RemoteKey key);

  Future<void> sendText(String text);
  Future<void> sendEnter();

  Future<List<DeviceInput>> inputs();
  Future<void> selectInput(String id);
  DeviceInput? get currentInput => null;
  Stream<DeviceInput?> get currentInputChanges => const Stream.empty();

  Future<List<DeviceApplication>> applications();
  Future<void> launchApplication(String id);
  Future<String?> currentApplication();

  /// Ids from the latest successful app-list response, or null when unknown.
  Set<String>? get reportedApplicationIds => null;

  Future<CurrentContent> currentContent();
  Stream<CurrentContent> watchCurrentContent();

  Future<void> startVoiceControl() => _unsupported('Voice control');
  Future<void> toggleGameMode() => _unsupported('Game mode');
  Future<void> syncWatchCompanion() => _unsupported('Watch companion');
}

Future<void> _unsupported(String feature) => Future.error(
  RemoteException('unsupported', '$feature is not supported by this device.'),
);

final class DeviceApplication {
  const DeviceApplication(this.id, this.name);
  final String id;
  final String name;
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
  });
  final String appId;
  final String? appName;
  final String? channelName;
  final String? channelNumber;
  bool get isLiveTv => appId == 'com.webos.app.livetv';
}

final class DeviceInput {
  const DeviceInput(this.id, this.name);
  final String id;
  final String name;
}

enum MediaAction { play, pause, stop, rewind, fastForward }

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
  blue('BLUE');

  const RemoteKey(this.wireName);
  final String wireName;
}

final class VolumeState {
  const VolumeState(this.volume, this.muted);
  final int volume;

  /// Null when the device reports volume without exposing mute feedback.
  final bool? muted;
}

typedef TvDeviceController = TVRemoteBase;
