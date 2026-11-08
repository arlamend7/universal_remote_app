import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:remote_core/remote_core.dart';

import '../widgets/grid/models/remote_preview_data.dart';
import 'preview_panel_session.dart';
import 'remote_panel.dart';

final class PreviewRemotePanel implements RemotePanel {
  PreviewRemotePanel(this.live, this.device, {this.sample = false})
    : connection = PreviewPanelSession(live.connection);

  final RemotePanel live;
  final bool sample;
  @override
  final RemoteDevice device;
  @override
  final PreviewPanelSession connection;

  bool get _ownsSession => live.device?.id == device.id;
  @override
  CurrentContent? get content => sample
      ? RemotePreviewData.example.content
      : _ownsSession
      ? live.content
      : null;
  @override
  DeviceInput? get currentInput => null;
  @override
  VolumeState? get volume => sample
      ? RemotePreviewData.example.volume
      : _ownsSession
      ? live.volume
      : null;
  @override
  bool get ready => sample || (_ownsSession && live.ready);
  @override
  bool get offline => !sample && (!_ownsSession || live.offline);
  @override
  bool get canChangeChannel =>
      sample || (_ownsSession && live.canChangeChannel);
  @override
  bool get canChangeVolume => sample || (_ownsSession && live.canChangeVolume);
  @override
  bool get canLaunchApps => sample || (_ownsSession && live.canLaunchApps);
  @override
  bool get canNavigate => sample || (_ownsSession && live.canNavigate);
  @override
  bool get canPowerOff => sample || (_ownsSession && live.canPowerOff);
  @override
  bool get canSelectInput => sample || (_ownsSession && live.canSelectInput);
  @override
  bool get canSetVolume => sample || (_ownsSession && live.canSetVolume);
  @override
  bool get canToggleMute => sample || (_ownsSession && live.canToggleMute);
  @override
  bool get canWake => false;

  @override
  String get contentTitle =>
      content?.appName ?? content?.appId ?? 'Current activity unavailable';
  @override
  String get contentSubtitle {
    if (sample) {
      final content = RemotePreviewData.example.content;
      return '${content.channelNumber} · ${content.channelName}';
    }
    return _ownsSession ? live.contentSubtitle : 'Not reported by this TV';
  }

  @override
  String get displayName => device.name;
  @override
  String get status => sample
      ? 'Connected'
      : _ownsSession
      ? live.status
      : 'Disconnected';

  @override
  Listenable get changes => live.changes;
  @override
  Listenable get contentChanges => live.contentChanges;
  @override
  Listenable get controlsChanges => live.controlsChanges;
  @override
  Listenable get sessionChanges => live.sessionChanges;
  @override
  Listenable get volumeChanges => live.volumeChanges;
  @override
  ValueListenable<List<RemoteDevice>> get profiles => live.profiles;
  @override
  ValueListenable<DateTime?> get sleepDeadline => live.sleepDeadline;

  @override
  Future<void> saveProfile(RemoteDevice device) async {}
  @override
  void scheduleSleep(RemoteDevice device, Duration duration) {}
  @override
  void cancelSleep() {}
  @override
  Future<void> showDeviceDetails(BuildContext context) async {}
  @override
  Future<void> switchDevice(BuildContext context) async {}
  @override
  Future<void> powerOff(
    BuildContext context, {
    Future<void> Function()? onConfirmed,
  }) async {}
  @override
  Future<void> press(NavigationKey key) async {}
  @override
  Future<void> channelDown() async {}
  @override
  Future<void> channelUp() async {}
  @override
  Future<void> volumeDown() async {}
  @override
  Future<void> volumeUp() async {}
  @override
  void previewVolume(double value) {}
  @override
  Future<void> setVolume(double value) async {}
  @override
  Future<void> toggleMute() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> retry() async {}
  @override
  Future<void> wake() async {}
}
