import 'dart:convert';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../contracts/engine_operation.dart';
import '../contracts/engine_session.dart';
import '../contracts/engine_session_context.dart';
import '../contracts/protocol_engine.dart';
import 'operations/ssap_kinds.dart';
import 'operations/ssap_operation_compiler.dart';
import 'ssap_engine_session.dart';

/// SSAP over WebSocket (TLS by default) with prompt pairing, a reusable
/// client key and a secondary pointer socket.
final class SsapEngine implements ProtocolEngine {
  SsapEngine({TransportConnector? connector}) : _connector = connector;

  final TransportConnector? _connector;

  @override
  String get id => 'ssap';

  @override
  Set<String> get kinds => SsapKinds.all;

  @override
  EngineOperation compile(OperationMapping mapping) =>
      SsapOperationCompiler.compile(mapping);

  @override
  Map<String, Object?> compileConnection(Map<String, Object?> json) {
    IntegrationJson.keys(
      json,
      const {
        'registration',
        'pairingTimeoutMs',
        'requestTimeoutMs',
        'allowLegacyTransport',
      },
      required: const {'registration'},
    );
    final registration = IntegrationJson.object(
      json['registration'],
      'registration',
    );
    _registration(registration);
    return {
      'registration': registration,
      'pairingTimeoutMs': IntegrationJson.integer(
        {'value': json['pairingTimeoutMs'] ?? 45000},
        'value',
        minimum: 5000,
        maximum: 120000,
      ),
      'requestTimeoutMs': IntegrationJson.integer(
        {'value': json['requestTimeoutMs'] ?? 8000},
        'value',
        minimum: 1000,
        maximum: 30000,
      ),
      'allowLegacyTransport': json['allowLegacyTransport'] == true,
    };
  }

  @override
  Future<EngineSession> open(EngineSessionContext context) =>
      SsapEngineSession.open(context, _connector ?? _pinned(context.device));

  /// The default transport pins the reviewed certificate, if any.
  static TransportConnector _pinned(RemoteDevice device) =>
      (uri) => IoWebSocketTransport.connect(
        uri,
        trustedCertificateDer: device.metadata['trustedCertificateDer'],
      );

  /// A prompt manifest: no signatures, vendor identities or extra keys.
  static void _registration(Map<String, Object?> manifest) {
    IntegrationJson.keys(
      manifest,
      const {'manifestVersion', 'appVersion', 'permissions'},
      required: const {'manifestVersion', 'permissions'},
    );
    final permissions = manifest['permissions'];
    if (permissions is! List<Object?> ||
        permissions.length > 64 ||
        !permissions.every(
          (value) =>
              value is String && RegExp(r'^[A-Z_]{1,64}$').hasMatch(value),
        ) ||
        utf8.encode(jsonEncode(manifest)).length > 8192) {
      throw const FormatException('Invalid SSAP registration manifest.');
    }
  }
}
