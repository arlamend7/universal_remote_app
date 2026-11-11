import 'dart:convert';

import 'package:remote_core/remote_core.dart';

import 'driver_step.dart';

/// A request supported by the persistent JSON session protocol.
final class DriverExchange {
  const DriverExchange._(this.operation, this._step, this.event);

  factory DriverExchange.parse(String source, DriverManifest manifest) {
    if (source.length > 16384) {
      throw const FormatException('Driver request exceeds the size limit.');
    }
    final step = DriverStep.fromJson(jsonDecode(source));
    if (!_operations.contains(step.operation) ||
        !manifest.runtime.operations.contains(step.operation)) {
      throw const FormatException('Unsupported driver request operation.');
    }
    final payload = jsonDecode(step.message!) as Map<String, Object?>;
    if (payload.keys.any(_reserved.contains)) {
      throw const FormatException('A driver request uses a reserved field.');
    }
    final event = payload['event'];
    if ((step.operation == DriverOperation.webSocketSubscribe ||
            step.operation == DriverOperation.webSocketUnsubscribe) &&
        event != null &&
        (event is! String || event.isEmpty || event.length > 64)) {
      throw const FormatException('Invalid subscription event name.');
    }
    return DriverExchange._(
      step.operation,
      step,
      event is String ? event : null,
    );
  }

  final DriverOperation operation;
  final DriverStep _step;
  final String? event;

  static const _reserved = {'id', 'code', 'token'};
  static const _operations = {
    DriverOperation.webSocketRequest,
    DriverOperation.webSocketSubscribe,
    DriverOperation.webSocketUnsubscribe,
    DriverOperation.webSocketAuthenticate,
    DriverOperation.webSocketPair,
  };

  String encode(
    int id, {
    String? code,
    String? token,
    Map<String, Object> arguments = const {},
  }) => jsonEncode({
    ...jsonDecode(_step.render(arguments)) as Map<String, Object?>,
    'id': id,
    if (code != null) 'code': code,
    if (token != null) 'token': token,
  });
}
