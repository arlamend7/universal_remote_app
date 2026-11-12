import 'dart:async';
import 'dart:convert';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import 'driver_text_session.dart';
import '../common/payload_template.dart';
import '../contracts/content_reading.dart';
import '../contracts/engine_operation.dart';
import '../contracts/engine_session.dart';
import '../contracts/engine_session_context.dart';
import 'json_websocket_kinds.dart';
import 'json_websocket_operation.dart';
import 'json_websocket_response.dart';

/// A persistent JSON session: `{id, ...}` requests answered by
/// `{id, ok}` replies, code pairing, token authentication and events.
final class JsonWebSocketEngineSession implements EngineSession {
  JsonWebSocketEngineSession._(this._timeout);

  static final _code = RegExp(r'^[A-Za-z0-9]{4,12}$');

  static Future<JsonWebSocketEngineSession> open(
    EngineSessionContext context,
    TransportConnector connector,
  ) async {
    final endpoint = context.device.endpoints.single;
    if (endpoint.scheme != 'wss' || !isLocalProbeAddress(endpoint.host)) {
      throw const RemoteException(
        'insecure',
        'Driver sessions require TLS to a local address.',
      );
    }
    final timeout = Duration(
      milliseconds: context.connection['timeoutMs']! as int,
    );
    final session = JsonWebSocketEngineSession._(timeout);
    session._text = DriverTextSession(
      await connector(endpoint),
      onEvent: session._event,
      onLost: session._finish,
    );
    try {
      await session._authorize(context);
    } catch (_) {
      await session.close();
      rethrow;
    }
    return session;
  }

  final Duration _timeout;
  late final DriverTextSession _text;
  final _events = StreamController<Map<String, Object?>>.broadcast();
  final _lost = Completer<void>();
  Future<void> _tail = Future.value();
  int _sequence = 0;
  bool _closed = false;

  @override
  Map<String, String> get facts => const {};
  @override
  Stream<void> get factChanges => const Stream.empty();
  @override
  DeviceSoftwareInformation? get software => null;
  @override
  String? get verifiedPeerIdentity => null;
  @override
  String? get reportedDiscoveryIdentity => null;
  @override
  Stream<Set<String>> get unavailable => const Stream.empty();
  @override
  Future<void> get lost => _lost.future;

  @override
  Future<Object?> execute(
    EngineOperation operation,
    Map<String, Object?> arguments,
  ) async {
    final call = operation as JsonWebSocketOperation;
    final reply = await _exchange(
      PayloadTemplate.parse(
        call.message,
        PayloadTemplate.arguments,
      ).render(arguments),
    );
    return _decode(call.result, reply);
  }

  @override
  Stream<Object?> subscribe(EngineOperation operation) {
    final call = operation as JsonWebSocketOperation;
    unawaited(
      _exchange(call.message).catchError((Object _) => <String, Object?>{}),
    );
    return _events.stream
        .where((event) => call.event == null || event['event'] == call.event)
        .map((event) => _decode(call.result, event));
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _text.close();
    _finish();
  }

  Future<void> _authorize(EngineSessionContext context) async {
    final key = context.credentialKey;
    var token = await context.credentials.read(key);
    if (token == null) {
      context.onState(DeviceConnectionState.pairing);
      token = await _pair(context);
      await context.credentials.write(key, token);
    }
    await _exchange({..._message(context, 'authentication'), 'token': token});
  }

  Future<String> _pair(EngineSessionContext context) async {
    final entered = Completer<String>();
    context.onPairingCode?.call((code) async {
      if (!_code.hasMatch(code) || entered.isCompleted) {
        return false;
      }
      entered.complete(code);
      return true;
    });
    try {
      final code = await entered.future.timeout(const Duration(minutes: 2));
      final reply = await _exchange({
        ..._message(context, 'pairing'),
        'code': code,
      });
      final token = reply['token'];
      if (token is! String || token.isEmpty || token.length > 4096) {
        throw const RemoteException('driverPairing', 'Invalid pairing token.');
      }
      return token;
    } finally {
      context.onPairingCode?.call(null);
    }
  }

  Future<Map<String, Object?>> _exchange(Map<String, Object?> message) {
    final result = _tail.then((_) => _send(message));
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result.timeout(_timeout);
  }

  Future<Map<String, Object?>> _send(Map<String, Object?> message) async {
    final id = ++_sequence;
    await _text.send(jsonEncode({...message, 'id': id}));
    final reply = await _text.receiveJson();
    if (reply['id'] != id) {
      throw const RemoteException('driverResponse', 'Mismatched TV response.');
    }
    if (reply['ok'] != true) {
      throw const RemoteException(
        'driverRejected',
        'The TV refused the request.',
      );
    }
    return reply;
  }

  void _event(Map<String, Object?> event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  void _finish() {
    if (!_lost.isCompleted && !_closed) {
      _lost.complete();
    }
    if (!_events.isClosed) {
      unawaited(_events.close());
    }
  }

  static Map<String, Object?> _message(
    EngineSessionContext context,
    String name,
  ) =>
      (context.connection[name]! as Map<String, Object?>)['message']!
          as Map<String, Object?>;

  static Object? _decode(String result, Map<String, Object?> reply) =>
      switch (result) {
        'volume' => JsonWebSocketResponse.volume(reply),
        'channels' => JsonWebSocketResponse.channels(reply),
        'inputs' => JsonWebSocketResponse.inputs(reply),
        'input' => JsonWebSocketResponse.input(reply),
        'applications' => JsonWebSocketResponse.applications(reply),
        'accessories' => JsonWebSocketResponse.accessories(reply),
        'content' => ContentReading(JsonWebSocketResponse.content(reply)),
        'application' => JsonWebSocketResponse.application(reply),
        'playback' => JsonWebSocketResponse.playback(reply),
        _ => null,
      };

  static void validateKind(String kind) {
    if (!JsonWebSocketKinds.all.contains(kind)) {
      throw FormatException('Unknown JSON WebSocket operation $kind.');
    }
  }
}
