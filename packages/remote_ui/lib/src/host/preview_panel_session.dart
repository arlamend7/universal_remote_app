import 'package:flutter/foundation.dart';
import 'package:remote_core/remote_core.dart';

import 'remote_panel_session.dart';

/// A preview observes the session but cannot acquire a live device controller.
final class PreviewPanelSession implements RemotePanelSession {
  const PreviewPanelSession(this.live);
  final RemotePanelSession live;

  @override
  DeviceController? get controller => null;
  @override
  ValueListenable<RemoteDevice?> get selected => live.selected;
  @override
  ValueListenable<DeviceConnectionState> get state => live.state;
  @override
  ValueListenable<int> get revision => live.revision;
  @override
  bool supports(RemoteCapability capability) => false;
  @override
  TVRemoteBase? tvWith(RemoteCapability capability) => null;
  @override
  Future<void> execute(
    Future<void> Function() command, {
    bool refreshVolume = false,
  }) async {}
  @override
  Future<void> refreshContent() async {}
  @override
  Future<void> powerOff() async {}
  @override
  void reportError(String message) {}
  @override
  void refreshControls() {}
}
