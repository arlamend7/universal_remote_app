import 'dart:async';
import 'dart:convert';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../connection/samsung_credentials.dart';

final class SamsungSession {
  SamsungSession(this.transport, this.onClosed);

  final TextTransport transport;
  final void Function() onClosed;
  StreamSubscription<String>? _messages;
  Completer<String?>? _approval;
  Completer<List<DeviceApplication>>? _catalog;
  bool _closed = false;
  bool get isClosed => _closed;

  Future<String?> authorize(Duration timeout) async {
    final approval = _approval = Completer<String?>();
    _messages = transport.messages.listen(
      _receive,
      onError: (Object _, StackTrace _) => _finish(),
      onDone: _finish,
    );
    try {
      return await approval.future.timeout(
        timeout,
        onTimeout: () {
          throw const RemoteException(
            'timeout',
            'The Samsung TV did not approve the connection in time.',
          );
        },
      );
    } finally {
      _approval = null;
    }
  }

  void _receive(String message) {
    Object? frame;
    try {
      frame = jsonDecode(message);
    } on FormatException {
      return;
    }
    switch (frame) {
      case {'event': 'ms.channel.connect', 'data': Map<String, dynamic> data}:
        _approve(data['token']);
      case {'event': 'ms.channel.unauthorized'}:
        _reject();
      case {
        'event': 'ed.installedApp.get',
        'data': {'data': List<dynamic> rows},
      }:
        _completeCatalog(rows);
    }
  }

  void _approve(Object? token) {
    final approval = _approval;
    if (approval == null || approval.isCompleted) {
      return;
    }
    final value = switch (token) {
      String text => text,
      int number => '$number',
      _ => null,
    };
    approval.complete(value != null && validSamsungToken(value) ? value : null);
  }

  void _reject() {
    final approval = _approval;
    if (approval == null || approval.isCompleted) {
      _finish();
      return;
    }
    approval.completeError(
      const RemoteException(
        'pairingDenied',
        'Samsung denied access. Allow Universal Remote on the TV and try again.',
      ),
    );
  }

  Future<List<DeviceApplication>> loadApplications() async {
    final catalog = _catalog = Completer<List<DeviceApplication>>();
    try {
      await _emit('ed.installedApp.get', '');
      return await catalog.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => [],
      );
    } finally {
      _catalog = null;
    }
  }

  void _completeCatalog(List<dynamic> rows) {
    final catalog = _catalog;
    if (catalog == null || catalog.isCompleted) {
      return;
    }
    final apps = <String, DeviceApplication>{};
    for (final row in rows.take(512)) {
      if (row case {'appId': String id, 'name': String name}
          when RegExp(r'^[a-zA-Z0-9._-]{1,128}$').hasMatch(id) &&
              name.trim().isNotEmpty &&
              name.length <= 200) {
        apps[id] = DeviceApplication(id, name.trim());
      }
    }
    catalog.complete(List.unmodifiable(apps.values));
  }

  Future<void> key(String key) => _send('ms.remote.control', {
    'Cmd': 'Click',
    'DataOfCmd': key,
    'Option': 'false',
    'TypeOfRemote': 'SendRemoteKey',
  });

  Future<void> launch(String id) =>
      _emit('ed.apps.launch', {'appId': id, 'action_type': 'DEEP_LINK'});

  Future<void> _emit(String event, Object data) =>
      _send('ms.channel.emit', {'event': event, 'to': 'host', 'data': data});

  Future<void> _send(String method, Map<String, Object> params) async {
    if (_closed) {
      throw const RemoteException(
        'network',
        'The Samsung TV connection closed.',
      );
    }
    try {
      await transport.send(jsonEncode({'method': method, 'params': params}));
    } catch (_) {
      throw const RemoteException(
        'network',
        'Could not send a command to the Samsung TV.',
      );
    }
  }

  void _finish() {
    if (_closed) {
      return;
    }
    _closed = true;
    final approval = _approval;
    if (approval != null && !approval.isCompleted) {
      approval.completeError(
        const RemoteException('network', 'The Samsung TV connection closed.'),
      );
    }
    final catalog = _catalog;
    if (catalog != null && !catalog.isCompleted) {
      catalog.complete([]);
    }
    onClosed();
  }

  Future<void> close() async {
    _finish();
    await _messages?.cancel();
    await transport.close();
  }
}
