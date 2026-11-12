import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../../ssap/services/ssap_client.dart';
import '../common/payload_template.dart';
import '../common/transport_connection_error.dart';
import '../contracts/engine_operation.dart';
import '../contracts/engine_session.dart';
import '../contracts/engine_session_context.dart';
import 'decoders/ssap_decoders.dart';
import 'identification/ssap_software_information.dart';
import 'operations/ssap_kinds.dart';
import 'operations/ssap_operation.dart';
import 'pointer/ssap_pointer_connection.dart';
import 'procedures/ssap_content_reader.dart';
import 'procedures/ssap_launch_target.dart';
import 'wake/ssap_wake_address_reader.dart';

/// An authenticated SSAP session plus its optional pointer socket.
final class SsapEngineSession implements EngineSession {
  SsapEngineSession._(
    this._client,
    this._endpoint,
    this._allowInsecure,
    TransportConnector connector,
  ) {
    _pointer = SsapPointerConnection(
      connector: connector,
      onUnavailable: _pointerLost,
    );
    unawaited(_client.disconnected.first.then((_) => _finish()));
  }

  /// Opens the transport, reads the saved key only after the socket is up,
  /// and registers; a rejected saved key is deleted and reported as revoked.
  static Future<SsapEngineSession> open(
    EngineSessionContext context,
    TransportConnector connector,
  ) async {
    final endpoint = _resolveEndpoint(context);
    final allowInsecure = context.device.metadata['allowInsecure'] == 'true';
    SsapClient? client;
    String? saved;
    try {
      final transport = await connector(endpoint);
      client = SsapClient(
        transport,
        requestTimeout: _duration(context.connection['requestTimeoutMs'], 8000),
      );
      saved = await context.credentials.read(context.credentialKey);
      context.onState(DeviceConnectionState.pairing);
      final key = await client.register(
        clientKey: saved,
        timeout: _duration(context.connection['pairingTimeoutMs'], 45000),
        manifest: context.connection['registration']! as Map<String, Object?>,
      );
      await context.credentials.write(context.credentialKey, key);
      return SsapEngineSession._(client, endpoint, allowInsecure, connector);
    } catch (error) {
      await client?.close();
      throw await _failure(context, error, saved);
    }
  }

  final SsapClient _client;
  final Uri _endpoint;
  final bool _allowInsecure;
  late SsapPointerConnection _pointer;
  late final _content = SsapContentReader(_query);
  final _facts = <String, String>{};
  final _factChanges = StreamController<void>.broadcast();
  final _unavailable = StreamController<Set<String>>.broadcast();
  final _lost = Completer<void>();
  DeviceSoftwareInformation? _software;
  bool _closed = false;

  @override
  Map<String, String> get facts => Map.unmodifiable(_facts);
  @override
  Stream<void> get factChanges => _factChanges.stream;
  @override
  DeviceSoftwareInformation? get software => _software;
  @override
  String? get verifiedPeerIdentity => null;
  @override
  String? get reportedDiscoveryIdentity => null;
  @override
  Stream<Set<String>> get unavailable => _unavailable.stream;
  @override
  Future<void> get lost => _lost.future;

  @override
  Future<Object?> execute(
    EngineOperation operation,
    Map<String, Object?> arguments,
  ) {
    final ssap = operation as SsapOperation;
    return switch (ssap.kind) {
      SsapKinds.request => _request(ssap, arguments),
      SsapKinds.pointerOpen => _openPointer(ssap),
      SsapKinds.pointerButton => _pointer.button(ssap.string('button')!),
      SsapKinds.pointerMove => _motion('move', arguments),
      SsapKinds.pointerScroll => _motion('scroll', arguments),
      SsapKinds.pointerClick => _pointer.click(),
      SsapKinds.readContent => _content.read(ssap),
      SsapKinds.launch => _launch(ssap, arguments),
      SsapKinds.launchReported => _launchReported(ssap),
      SsapKinds.toggleAccessory => _toggleAccessory(ssap, arguments),
      SsapKinds.identify => _identify(ssap),
      SsapKinds.wakeAddress => _wakeAddress(ssap),
      _ => Future.error(
        RemoteException('unsupported', '${ssap.kind} is not executable.'),
      ),
    };
  }

  @override
  Stream<Object?> subscribe(EngineOperation operation) {
    final ssap = operation as SsapOperation;
    final updates = _client.subscribe(ssap.uri);
    if (ssap.string('result') == 'content') {
      return updates.asyncMap((response) => _content.decode(ssap, response));
    }
    return updates.asyncMap((response) => _volume(ssap, response));
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _pointer.close();
    await _client.close();
    await _finish();
  }

  Future<Object?> _request(
    SsapOperation operation,
    Map<String, Object?> arguments,
  ) async {
    final payload = PayloadTemplate.parse(
      operation.parameters['payload'],
      PayloadTemplate.arguments,
    ).render(arguments);
    final response = await _client.request(
      operation.uri,
      payload: payload,
      timeout: operation.timeout,
    );
    return _decode(operation, response);
  }

  Future<Object?> _decode(
    SsapOperation operation,
    Map<String, Object?> response,
  ) async => switch (operation.string('result')) {
    'volume' => _volume(operation, response),
    'applications' => _applications(response),
    'inputs' => decodeSsapInputs(response),
    'channels' => decodeSsapChannels(response),
    'accessories' => decodeSsapAccessories(response),
    _ => null,
  };

  Future<VolumeState> _volume(
    SsapOperation operation,
    Map<String, Object?> response,
  ) {
    final mute = operation.string('muteUri');
    return decodeSsapVolume(
      response,
      mute == null ? null : () => _client.request(mute),
    );
  }

  List<DeviceApplication> _applications(Map<String, Object?> response) {
    final list = decodeSsapApplications(response, _endpoint.host);
    _facts
      ..removeWhere((key, _) => key.startsWith('application.'))
      ..['applications.reported'] = 'true'
      ..addAll({
        for (final id in list.reported)
          if (IntegrationJson.isIdentifier('application.$id'))
            'application.$id': 'present',
      });
    _factChanges.add(null);
    return list.visible;
  }

  Future<void> _openPointer(SsapOperation operation) async {
    final response = await _client.request(operation.uri);
    await _pointer.open(
      response['socketPath'],
      _endpoint,
      allowInsecure: _allowInsecure,
    );
    _facts['pointer.open'] = '${_pointer.isOpen}';
    _factChanges.add(null);
  }

  Future<void> _motion(String type, Map<String, Object?> arguments) {
    final dx = arguments['dx'];
    final dy = arguments['dy'];
    if (dx is! num || dy is! num) {
      throw ArgumentError('Invalid pointer motion.');
    }
    return _pointer.motion(type, dx.toDouble(), dy.toDouble());
  }

  Future<void> _launch(
    SsapOperation operation,
    Map<String, Object?> arguments,
  ) async {
    final target = SsapLaunchTarget.parse('${arguments['target'] ?? ''}');
    final web = target.web;
    final open = operation.string('openUri');
    if (web != null && open != null) {
      await _client.request(open, payload: {'target': web.toString()});
      return;
    }
    if (web != null) {
      throw const RemoteException('appLink', 'Web addresses are unsupported.');
    }
    await _client.request(
      operation.uri,
      payload: {'id': target.id, 'contentId': ?target.contentId},
    );
  }

  Future<void> _launchReported(SsapOperation operation) async {
    final id = operation.string('applicationId')!;
    if (_facts['application.$id'] != 'present') {
      throw const RemoteException(
        'unsupported',
        'The TV does not report this app.',
      );
    }
    await _client.request(
      operation.uri,
      payload: {
        'id': id,
        ...operation.parameters['params']! as Map<String, Object?>,
      },
    );
  }

  Future<void> _toggleAccessory(
    SsapOperation operation,
    Map<String, Object?> arguments,
  ) async {
    final id = '${arguments['target'] ?? ''}'.toUpperCase();
    final devices = decodeSsapAccessories(await _client.request(operation.uri));
    final target = devices.where((item) => item.id == id).firstOrNull;
    if (target == null) {
      throw const RemoteException(
        'accessory',
        'This accessory is no longer paired with the TV.',
      );
    }
    final method = target.connected
        ? operation.string('disconnectUri')!
        : operation.string('connectUri')!;
    await _client.request(method, payload: {'address': target.id});
  }

  Future<DeviceSoftwareInformation?> _identify(SsapOperation operation) async {
    final info = await _client.request(operation.uri);
    return _software = ssapSoftwareInformation(
      info,
      osVersionPrefix: operation.string('osVersionPrefix'),
      operatingSystem: operation.string('operatingSystem'),
    );
  }

  Future<DeviceWakeAddress?> _wakeAddress(SsapOperation operation) async {
    final service = operation.string('service')!.substring('ssap://'.length);
    return SsapWakeAddressReader(
      _client,
      service: service,
    ).read(_endpoint.host);
  }

  Future<Map<String, Object?>> _query(String uri) => _client.request(uri);

  void _pointerLost() {
    if (_closed || _unavailable.isClosed) {
      return;
    }
    _facts['pointer.open'] = 'false';
    _unavailable.add(const {
      SsapKinds.pointerButton,
      SsapKinds.pointerMove,
      SsapKinds.pointerScroll,
      SsapKinds.pointerClick,
      SsapKinds.pointerOpen,
    });
  }

  Future<void> _finish() async {
    if (!_lost.isCompleted && !_closed) {
      _lost.complete();
    }
    await _pointer.close();
    if (!_factChanges.isClosed) {
      await _factChanges.close();
      await _unavailable.close();
    }
  }

  static Uri _resolveEndpoint(EngineSessionContext context) {
    final endpoint = context.device.endpoints.firstOrNull;
    if (endpoint == null) {
      throw const RemoteException(
        'endpoint',
        'No TV network endpoint is configured.',
      );
    }
    final allowLegacy = context.connection['allowLegacyTransport'] == true;
    final optedIn = context.device.metadata['allowInsecure'] == 'true';
    if (endpoint.scheme == 'ws' && (!allowLegacy || !optedIn)) {
      throw const RemoteException(
        'insecure',
        'Legacy unencrypted transport requires explicit permission.',
      );
    }
    return endpoint;
  }

  static Future<RemoteException> _failure(
    EngineSessionContext context,
    Object error,
    String? saved,
  ) async {
    final failure = transportConnectionError(error);
    if (failure.code != 'pairingRejected' || saved == null) {
      return failure;
    }
    await context.credentials.delete(context.credentialKey);
    return const RemoteException(
      'revokedKey',
      'The saved authorization was rejected. Pair again and approve on the TV.',
    );
  }

  static Duration _duration(Object? value, int fallback) =>
      Duration(milliseconds: value is int ? value : fallback);
}
