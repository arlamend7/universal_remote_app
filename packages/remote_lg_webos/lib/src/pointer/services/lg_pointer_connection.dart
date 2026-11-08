import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../../connection/models/lg_connection_options.dart';
import '../functions/encode_lg_navigation.dart';

/// Owns the pointer socket and its lifecycle independently of SSAP.
final class LgPointerConnection {
  LgPointerConnection({required this.connector, required this.onUnavailable});
  final TransportConnector connector;
  final void Function() onUnavailable;
  TextTransport? _transport;
  StreamSubscription<String>? _messages;
  int _generation = 0;
  Future<void> open(
    Object? address,
    Uri main,
    LgConnectionOptions options,
  ) async {
    final uri = _endpoint(address, main, options);
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

  Uri _endpoint(Object? address, Uri main, LgConnectionOptions options) {
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
    if (uri.scheme == 'ws' && !options.allowInsecure) {
      throw const RemoteException(
        'insecure',
        'The pointer socket requires explicit legacy-transport permission.',
      );
    }
    return uri;
  }

  void specialKey(RemoteKey key) =>
      _send('type:button\nname:${key.wireName}\n\n');
  void motion(String type, double dx, double dy) {
    if (!{'move', 'scroll'}.contains(type) ||
        !dx.isFinite ||
        !dy.isFinite ||
        dx.abs() > 10000 ||
        dy.abs() > 10000) {
      throw ArgumentError('Invalid pointer motion.');
    }
    _send('type:$type\ndx:${dx.round()}\ndy:${dy.round()}\ndown:0\n\n');
  }

  void click() => _send('type:click\n\n');

  void press(NavigationKey key) => _send(encodeLgNavigation(key));
  void _send(String frame) {
    final transport = _transport;
    if (transport == null) {
      throw const RemoteException(
        'pointer',
        'Navigation is unavailable on this TV connection.',
      );
    }
    try {
      transport.send(frame);
    } catch (_) {
      onUnavailable();
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
