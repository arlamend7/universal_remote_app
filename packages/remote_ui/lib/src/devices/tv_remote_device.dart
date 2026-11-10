import 'package:remote_core/remote_core.dart';

/// TV operations used by typed dashboard definitions. Eligibility is external.
abstract interface class TvRemoteDevice {
  CurrentContent? get currentActivity;
  DeviceInput? get currentInput;
  Future<void> startVoiceControl();
  Future<void> toggleGameMode();
  Future<void> syncWatchCompanion();
  Future<void> navigate(NavigationKey key);
  Future<void> channelUp();
  Future<void> channelDown();
  Future<void> media(MediaAction action);
  bool get mediaPlaying;
  Future<void> togglePlayback();
  Future<void> key(RemoteKey key);
  Future<void> click();
  Future<void> move(double x, double y, {bool scroll = false});
  Future<void> sendText(String text, {bool submit = false});
  Future<List<BluetoothAccessory>> bluetoothAccessories();
  Future<void> toggleBluetoothAccessory(String id);
  Future<List<DeviceInput>> installedInputs();
  Future<void> input(String id);
  Future<List<DeviceChannel>> installedChannels();
  Future<void> channel(String id);
  Future<void> mute(bool? value);
  Future<void> volumeUp();
  Future<void> volumeDown();
  void previewVolume(double value);
  Future<void> setVolume(double value);
  Future<List<DeviceApplication>> installedApps();
  Future<void> launchApp(DeviceApplication app);
  Future<void> openInputPicker();
}
