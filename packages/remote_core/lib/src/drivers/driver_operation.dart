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
  webSocketPair('websocket.pair');

  const DriverOperation(this.id);
  final String id;

  static DriverOperation parse(String id) {
    final operation = values.where((value) => value.id == id).firstOrNull;
    if (operation == null) {
      throw const FormatException('Unknown required driver operation.');
    }
    return operation;
  }
}
