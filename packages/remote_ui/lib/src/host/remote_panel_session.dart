import 'package:flutter/foundation.dart';
import 'package:remote_core/remote_core.dart';

abstract interface class RemotePanelSession {
  DeviceController? get controller;
  ValueListenable<RemoteDevice?> get selected;
  ValueListenable<DeviceConnectionState> get state;
  ValueListenable<int> get revision;

  /// Whether the connected session reports [capability].
  bool supports(RemoteCapability capability);

  /// The connected TV driver, only when it reports [capability].
  TVRemoteBase? tvWith(RemoteCapability capability);
  Future<void> execute(
    Future<void> Function() command, {
    bool refreshVolume = false,
  });
  Future<void> refreshContent();
  Future<void> powerOff();
  void reportError(String message);
  void refreshControls();
}
