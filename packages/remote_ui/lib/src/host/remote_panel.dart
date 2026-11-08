import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:remote_core/remote_core.dart';

import 'remote_panel_session.dart';

/// The device and application actions required by a dashboard.
abstract interface class RemotePanel {
  RemotePanelSession get connection;
  RemoteDevice? get device;
  CurrentContent? get content;
  DeviceInput? get currentInput;
  VolumeState? get volume;
  bool get ready;
  bool get offline;
  bool get canChangeChannel;
  bool get canChangeVolume;
  bool get canLaunchApps;
  bool get canNavigate;
  bool get canPowerOff;
  bool get canSelectInput;
  bool get canSetVolume;
  bool get canToggleMute;
  bool get canWake;
  String get contentSubtitle;
  String get contentTitle;
  String get displayName;
  String get status;
  Listenable get changes;
  Listenable get contentChanges;
  Listenable get controlsChanges;
  Listenable get sessionChanges;
  Listenable get volumeChanges;
  ValueListenable<List<RemoteDevice>> get profiles;
  ValueListenable<DateTime?> get sleepDeadline;
  Future<void> saveProfile(RemoteDevice device);
  void scheduleSleep(RemoteDevice device, Duration duration);
  void cancelSleep();
  Future<void> showDeviceDetails(BuildContext context);
  Future<void> switchDevice(BuildContext context);
  Future<void> powerOff(
    BuildContext context, {
    Future<void> Function()? onConfirmed,
  });
  Future<void> press(NavigationKey key);
  Future<void> channelDown();
  Future<void> channelUp();
  Future<void> volumeDown();
  Future<void> volumeUp();
  void previewVolume(double value);
  Future<void> setVolume(double value);
  Future<void> toggleMute();
  Future<void> disconnect();
  Future<void> retry();
  Future<void> wake();
}
