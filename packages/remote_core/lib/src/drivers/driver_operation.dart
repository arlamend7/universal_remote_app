import '../providers/models/provider_identity.dart';

/// Wire IDs for compiled operations recognized by the driver contract.
enum DriverOperation {
  webSocketConnect('websocket.connect'),
  webSocketSendJson('websocket.sendJson'),
  webSocketAwaitJson('websocket.awaitJson'),
  webSocketDisconnect('websocket.disconnect'),
  webSocketRequest('websocket.request'),
  webSocketSubscribe('websocket.subscribe'),
  webSocketUnsubscribe('websocket.unsubscribe'),
  webSocketAuthenticate('websocket.authenticate'),
  webSocketPair('websocket.pair'),
  compiledBindings('compiled.bindings'),
  remoteV2Session('remote-v2.session', provider: ProviderIdentity.androidTv),
  samsungSession('samsung.session', provider: ProviderIdentity.samsungTizen),
  rokuEcp('roku.ecp', provider: ProviderIdentity.roku);

  const DriverOperation(this.id, {this.provider});
  final String id;
  final ProviderIdentity? provider;

  static DriverOperation parse(String id) {
    final operation = values.where((value) => value.id == id).firstOrNull;
    if (operation == null) {
      throw const FormatException('Unknown required driver operation.');
    }
    return operation;
  }
}
