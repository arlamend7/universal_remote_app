import 'dart:io';

import 'package:flutter/services.dart';

/// Android owns the multicast lock; other targets use their OS network policy.
final class MulticastNetworkAccess {
  static const _channel = MethodChannel(
    'br.net.devcom.universal_remote/network',
  );
  Future<void> acquire() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('acquireMulticast');
  }

  Future<void> release() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('releaseMulticast');
  }
}
