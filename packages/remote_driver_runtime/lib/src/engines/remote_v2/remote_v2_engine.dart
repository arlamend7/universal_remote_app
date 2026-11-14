import 'dart:io';

import 'package:remote_core/remote_core.dart';

import '../../remote_v2/protocol/android_remote_session.dart';
import '../../remote_v2/security/paired_identity.dart';
import '../common/engine_parameters.dart';
import '../common/transport_connection_error.dart';
import '../contracts/engine_operation.dart';
import '../contracts/engine_session.dart';
import '../contracts/engine_session_context.dart';
import '../contracts/offline_wake_engine.dart';
import '../contracts/protocol_engine.dart';
import 'remote_v2_engine_session.dart';
import 'remote_v2_kinds.dart';
import 'remote_v2_operation.dart';

/// Android TV Remote v2: certificate pairing, pinned TLS and binary framing.
/// Integrations only choose validated Android `KeyEvent` codes.
final class RemoteV2Engine implements ProtocolEngine, OfflineWakeEngine {
  RemoteV2Engine({this.portOverride, this.pairingPortOverride});

  /// Test seam for a loopback TLS endpoint; null uses the declared port.
  final int? portOverride;

  /// Test seam for a loopback pairing endpoint; null uses port 6467.
  final int? pairingPortOverride;

  /// Android `KeyEvent` codes are non-negative and below this bound.
  static const maximumKeyCode = 319;

  @override
  String get id => 'android-remote-v2';

  @override
  Set<String> get kinds => RemoteV2Kinds.all;

  @override
  EngineOperation compile(OperationMapping mapping) {
    final values = EngineParameters(mapping.kind, mapping.parameters);
    if (mapping.kind == RemoteV2Kinds.wake) {
      return _compileWake(values);
    }
    if (mapping.kind != RemoteV2Kinds.key) {
      values.only(const {});
      return RemoteV2Operation(mapping.kind, const {});
    }
    values.only(const {'code'}, required: const {'code'});
    return RemoteV2Operation(mapping.kind, {
      'code': values.integer('code', minimum: 0, maximum: maximumKeyCode),
    });
  }

  RemoteV2Operation _compileWake(EngineParameters values) {
    const fields = {'code', 'portMetadata', 'fallbackPorts'};
    values.only(fields, required: fields);
    return RemoteV2Operation(RemoteV2Kinds.wake, {
      'code': values.integer('code', minimum: 224, maximum: 224),
      'portMetadata': values.string(
        'portMetadata',
        RegExp(r'[a-zA-Z0-9_]{1,40}'),
      ),
      'fallbackPorts': {
        for (final entry in IntegrationJson.object(
          values.raw('fallbackPorts'),
          'fallbackPorts',
        ).entries)
          entry.key: _wakePort(entry.value),
      },
    });
  }

  int _wakePort(Object? value) => IntegrationJson.integer(
    {'port': value},
    'port',
    minimum: 1024,
    maximum: 65535,
  );

  @override
  bool canWakeOffline(RemoteDevice device, EngineOperation operation) =>
      operation is RemoteV2Operation &&
      operation.kind == RemoteV2Kinds.wake &&
      device.metadata.containsKey(DeviceMetadataKeys.verifiedPeerIdentity) &&
      _wakeTarget(device, operation) != null;

  (Uri, int)? _wakeTarget(RemoteDevice device, RemoteV2Operation operation) {
    final endpoint = device.endpoints.singleOrNull;
    if (endpoint == null ||
        endpoint.scheme != 'tls' ||
        !_local(endpoint.host)) {
      return null;
    }
    final advertised = device.metadata[operation.parameters['portMetadata']];
    final port =
        int.tryParse(advertised ?? '') ??
        (operation.parameters['fallbackPorts']!
            as Map<String, int>)[device.model];
    if (port == null || port < 1024 || port > 65535 || port == endpoint.port) {
      return null;
    }
    return (endpoint, port);
  }

  bool _local(String host) =>
      isLocalProbeAddress(host) ||
      (portOverride != null &&
          InternetAddress.tryParse(host)?.isLoopback == true);

  @override
  Future<void> wakeOffline(
    RemoteDevice device,
    EngineOperation operation, {
    required CredentialStore credentials,
  }) async {
    if (!canWakeOffline(device, operation)) {
      throw const RemoteException(
        'wakeUnavailable',
        'Network wake is unavailable for this TV.',
      );
    }
    final mapping = operation as RemoteV2Operation;
    final (endpoint, wakePort) = _wakeTarget(device, mapping)!;
    final stored = await credentials.read(device.id);
    if (stored == null) {
      throw const RemoteException(
        'wakeUnavailable',
        'Pair with the TV while it is on before using network wake.',
      );
    }
    final identity = PairedIdentity.decode(stored);
    if (identity.fingerprint !=
        device.metadata[DeviceMetadataKeys.verifiedPeerIdentity]) {
      throw const RemoteException(
        'certificate',
        'The saved pairing does not match this TV.',
      );
    }
    await const DeviceConnectionWorkflow(
      wakeAttempts: 3,
      retryDelay: Duration(milliseconds: 500),
    ).run(
      wake: () => _knock(endpoint.host, wakePort),
      connect: () => _wakeScreen(endpoint, identity, mapping.code),
      isCurrent: () => true,
      canRetry: (error) =>
          error is RemoteException &&
          const {
            'connectionRefused',
            'network',
            'timeout',
          }.contains(error.code),
      reset: () async {},
    );
  }

  Future<void> _knock(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 1),
      );
      socket.destroy();
    } on SocketException {
      // Some wake ports drop the connection as the normal remote port comes up.
    }
  }

  Future<void> _wakeScreen(
    Uri endpoint,
    PairedIdentity identity,
    int code,
  ) async {
    final session = AndroidRemoteSession(
      endpoint.host,
      identity,
      port: portOverride ?? endpoint.port,
    );
    try {
      await session.connect(() {}).timeout(const Duration(seconds: 3));
      await session.key(code);
    } on Exception catch (error, stack) {
      Error.throwWithStackTrace(transportConnectionError(error), stack);
    } finally {
      session.close();
    }
  }

  @override
  Map<String, Object?> compileConnection(Map<String, Object?> json) {
    IntegrationJson.keys(json, const {'port', 'operatingSystem'});
    return {
      'port': IntegrationJson.integer(
        {'port': json['port'] ?? 6466},
        'port',
        minimum: 1,
        maximum: 65535,
      ),
      'operatingSystem': IntegrationJson.optionalLabel(json, 'operatingSystem'),
    };
  }

  @override
  Future<EngineSession> open(EngineSessionContext context) =>
      RemoteV2EngineSession.open(
        context,
        portOverride: portOverride,
        pairingPortOverride: pairingPortOverride,
      );
}
