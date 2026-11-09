import 'package:flutter/services.dart';

abstract final class ScreenAwake {
  static const _channel = MethodChannel(
    'br.net.devcom.universal_remote/display',
  );

  static Future<void> setEnabled(bool enabled) =>
      _channel.invokeMethod<void>('setScreenAwake', enabled);
}
