/// Operation kinds of the generic JSON-over-WebSocket engine.
abstract final class JsonWebSocketKinds {
  static const request = 'json-websocket.request';
  static const subscribe = 'json-websocket.subscribe';

  static const all = {request, subscribe};

  /// Typed decoders a request may name.
  static const results = {
    'none',
    'volume',
    'channels',
    'inputs',
    'input',
    'applications',
    'accessories',
    'content',
    'application',
    'playback',
  };
}
