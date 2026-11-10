import 'dart:convert';

import 'package:remote_core/remote_core.dart';

import 'wire_message.dart';

final class AndroidEditor {
  int? _id;
  int? _counter;
  int _start = 0;
  int _end = 0;
  int _action = 0;
  String? package;

  void focus(List<int> payload) {
    reset();
    final message = WireMessage.decode(payload);
    final raw = message[1];
    if (raw is! List<int>) {
      return;
    }
    final info = WireMessage.decode(raw);
    final application = info[12];
    package = application is List<int>
        ? utf8.decode(application, allowMalformed: true)
        : null;
    final id = info[1];
    final action = info[6];
    if (id is! int || id <= 0 || (info[2] ?? 0) == 0) {
      return;
    }
    _id = id;
    _action = action is int ? action : 0;
    _status(message[2]);
  }

  void receiveText(List<int> payload) =>
      _status(WireMessage.decode(payload)[2]);

  void selection(List<int> payload) =>
      _selection(WireMessage.decode(payload), 2, 3);

  void _status(Object? payload) {
    if (payload is! List<int> || _id == null) {
      return;
    }
    final state = WireMessage.decode(payload);
    final counter = state[1] ?? 0;
    _counter = counter is int && counter >= 0 ? counter : null;
    _selection(state, 3, 4);
  }

  void _selection(Map<int, Object> fields, int first, int last) {
    final start = fields[first] ?? 0;
    final end = fields[last] ?? 0;
    if (start is int && end is int && start >= 0 && end >= 0) {
      _start = start <= end ? start : end;
      _end = end >= start ? end : start;
    }
  }

  void reset() {
    _id = null;
    _counter = null;
    _action = 0;
    _start = 0;
    _end = 0;
    package = null;
  }

  Map<int, Object> text(String value) =>
      _edit(2, {1: _start, 2: _end, 3: value});

  Map<int, Object>? get submit => _action > 0 ? _edit(5, {1: _action}) : null;

  Map<int, Object> _edit(int operation, Map<int, Object> values) {
    final id = _id;
    final counter = _counter;
    if (id == null || counter == null) {
      throw const RemoteException(
        'keyboardFocus',
        'Open a text field on the TV first.',
      );
    }
    return {
      1: id,
      2: counter,
      3: WireMessage.encode({operation: WireMessage.encode(values)}),
    };
  }
}
