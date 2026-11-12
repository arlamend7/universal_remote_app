import 'package:flutter/services.dart';

Future<void> openDiscoverySettings() async {
  try {
    await const MethodChannel('br.net.devcom.universal_remote/network_settings')
        .invokeMethod<void>('open');
  } on PlatformException {
    // The on-screen instructions remain available if settings cannot open.
  } on MissingPluginException {
    // Desktop platforms do not expose this action.
  }
}
