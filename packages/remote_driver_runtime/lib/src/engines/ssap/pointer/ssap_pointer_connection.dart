import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import 'pointer_button_frame.dart';

/// Owns the SSAP pointer socket and its lifecycle independently of the
/// main session; only the host of the authenticated session is accepted.
final class SsapPointerConnection {
  SsapPointerConnection({required this.connector, required this.onUnavailable});
  final TransportConnector connector;
  final void Function() onUnavailable;
  TextTransport? _transport;
  StreamSubscription<String>? _messages;
  int _generation = 0;
  Future<void> open(
    Object? address,
    Uri main, {
    required bool allowInsecure,
  }) async {
    final uri = _endpoint(address, main, allowInsecure);
    final generation = ++_generation;
    final transport = await connector(uri);
    if (generation != _generation) {
      await transport.close();
      return;
    }
    _transport = transport;
    _messages = transport.messages.listen(
      _ignoreMessage,
      onDone: onUnavailable,
      onError: _socketFailed,
    );
  }

  Uri _endpoint(Object? address, Uri main, bool allowInsecure) {
    final uri = address is String ? Uri.tryParse(address) : null;
    if (uri == null ||
        !{'ws', 'wss'}.contains(uri.scheme) ||
        uri.host != main.host ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      throw const RemoteException(
        'pointer',
        'The TV returned an invalid pointer endpoint.',
      );
    }
    if (uri.scheme == 'ws' && !allowInsecure) {
      throw const RemoteException(
        'insecure',
        'The pointer socket requires explicit legacy-transport permission.',
      );
    }
    return uri;
  }

  bool get isOpen => _transport != null;

  Future<void> button(String name) {
    if (pointerButtonName.firstMatch(name)?.end != name.length) {
      throw ArgumentError('Invalid pointer button.');
    }
    return _send(pointerButtonFrame(name));
  }

  Future<void> motion(String type, double dx, double dy) {
    if (!{'move', 'scroll'}.contains(type) ||
        !dx.isFinite ||
        !dy.isFinite ||
        dx.abs() > 10000 ||
        dy.abs() > 10000) {
      throw ArgumentError('Invalid pointer motion.');
    }
    return _send('type:$type\ndx:${dx.round()}\ndy:${dy.round()}\ndown:0\n\n');
  }

  Future<void> click() => _send('type:click\n\n');

  Future<void> _send(String frame) async {
    final transport = _transport;
    if (transport == null) {
      throw const RemoteException(
        'pointer',
        'Navigation is unavailable on this TV connection.',
      );
    }
    try {
      await transport.send(frame);
    } catch (_) {
      if (identical(_transport, transport)) {
        onUnavailable();
      }
      throw const RemoteException(
        'pointer',
        'The TV navigation socket disconnected.',
      );
    }
  }

  void _ignoreMessage(String _) {}
  void _socketFailed(Object _) => onUnavailable();
  Future<void> close() async {
    ++_generation;
    final transport = _transport;
    _transport = null;
    await _messages?.cancel();
    _messages = null;
    await transport?.close();
  }
}
