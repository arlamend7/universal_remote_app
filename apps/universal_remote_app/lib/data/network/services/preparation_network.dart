import 'package:flutter/services.dart';

typedef PreparationNetwork = ({
  String? transport,
  String? name,
  bool canRequestName,
});

const _channel = MethodChannel('br.net.devcom.universal_remote/local_network');
const PreparationNetwork unknownPreparationNetwork = (
  transport: null,
  name: null,
  canRequestName: false,
);

Future<PreparationNetwork> readPreparationNetwork() async {
  try {
    final snapshot = await _channel.invokeMapMethod<String, Object?>(
      'snapshot',
    );
    return (
      transport: snapshot?['transport'] as String?,
      name: snapshot?['name'] as String?,
      canRequestName: snapshot?['canRequestName'] == true,
    );
  } on PlatformException {
    return unknownPreparationNetwork;
  } on MissingPluginException {
    return unknownPreparationNetwork;
  }
}

Future<void> requestWifiNamePermission() async {
  try {
    await _channel.invokeMethod<void>('requestNamePermission');
  } on PlatformException {
    // Setup remains available when the system cannot show the request.
  } on MissingPluginException {
    // Platform does not support querying a Wi-Fi name.
  }
}
