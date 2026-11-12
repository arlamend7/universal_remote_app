import 'package:remote_core/remote_core.dart';

import 'engine_operation.dart';

/// Runtime-level operations that need no device session.
final class NetworkOperation implements EngineOperation {
  NetworkOperation._(this.kind, this._parameters);

  factory NetworkOperation.compile(OperationMapping mapping) {
    if (mapping.parameters.keys.any((key) => key != 'broadcast')) {
      throw const FormatException('Invalid wake-on-LAN parameters.');
    }
    final broadcast = mapping.parameters['broadcast'];
    if (broadcast != null &&
        (broadcast is! String ||
            !RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(broadcast))) {
      throw const FormatException('Invalid wake-on-LAN broadcast address.');
    }
    return NetworkOperation._(
      mapping.kind,
      Map.unmodifiable(mapping.parameters),
    );
  }

  @override
  final String kind;
  final Map<String, Object?> _parameters;

  String? get broadcast => _parameters['broadcast'] as String?;

  @override
  Map<String, Object?> describe() => _parameters;
}
