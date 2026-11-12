import 'dart:async';
import 'dart:convert';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../../samsung/connection/samsung_credentials.dart';
import '../../samsung/protocol/samsung_session.dart';
import '../contracts/engine_operation.dart';
import '../contracts/engine_session.dart';
import '../contracts/engine_session_context.dart';
import 'samsung_channel_kinds.dart';

/// A token-authorized Samsung remote channel over a pinned WebSocket.
final class SamsungChannelEngineSession implements EngineSession {
  SamsungChannelEngineSession._(this._session, this._applications);

  static Future<SamsungChannelEngineSession> open(
    EngineSessionContext context,
    Future<TextTransport> Function(Uri, String) openTransport,
  ) async {
    final pin =
        context.device.metadata[DeviceMetadataKeys.trustedCertificateDer];
    if (pin == null || pin.isEmpty) {
      throw const RemoteException(
        'tls',
        'Review the Samsung TV certificate before pairing.',
      );
    }
    final token = samsungToken(
      await context.credentials.read(context.credentialKey),
      pin,
    );
    final lost = Completer<void>();
    final session = await _connect(context, openTransport, pin, token, lost);
    final List<DeviceApplication> apps;
    try {
      apps = await _authorized(context, session, pin, token);
    } catch (_) {
      await session.close();
      rethrow;
    }
    final result = SamsungChannelEngineSession._(session, apps);
    unawaited(lost.future.then((_) => result._finish()));
    return result;
  }

  static Future<List<DeviceApplication>> _authorized(
    EngineSessionContext context,
    SamsungSession session,
    String pin,
    String? token,
  ) async {
    final issued = await _authorize(context, session, token);
    if (issued != null && issued != token) {
      await context.credentials.write(
        context.credentialKey,
        encodeSamsungToken(pin, issued),
      );
    }
    final apps = await session.loadApplications();
    if (session.isClosed) {
      throw const RemoteException(
        'network',
        'The Samsung TV connection closed.',
      );
    }
    return apps;
  }

  static Future<SamsungSession> _connect(
    EngineSessionContext context,
    Future<TextTransport> Function(Uri, String) openTransport,
    String pin,
    String? token,
    Completer<void> lost,
  ) async {
    final endpoint = context.device.endpoints.single.replace(
      queryParameters: {
        'name': base64Encode(
          utf8.encode(context.connection['clientName']! as String),
        ),
        'token': ?token,
      },
    );
    final transport = await openTransport(endpoint, pin);
    return SamsungSession(transport, () {
      if (!lost.isCompleted) {
        lost.complete();
      }
    });
  }

  static Future<String?> _authorize(
    EngineSessionContext context,
    SamsungSession session,
    String? token,
  ) async {
    if (token == null) {
      context.onState(DeviceConnectionState.pairing);
    }
    try {
      return await session.authorize(
        Duration(
          milliseconds: context.connection['authorizeTimeoutMs']! as int,
        ),
      );
    } on RemoteException catch (error) {
      if (token != null && error.code == 'pairingDenied') {
        await context.credentials.delete(context.credentialKey);
      }
      rethrow;
    }
  }

  final SamsungSession _session;
  final List<DeviceApplication> _applications;
  final _lost = Completer<void>();
  bool _closed = false;

  static final _appId = RegExp(r'^[a-zA-Z0-9._-]{1,128}$');

  @override
  Map<String, String> get facts => {
    'applications.reported': '${_applications.isNotEmpty}',
  };
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
    _requireOpen();
    return switch (operation.kind) {
      SamsungChannelKinds.key => _session.key(
        operation.describe()['key']! as String,
      ),
      SamsungChannelKinds.launch => _launch(arguments),
      SamsungChannelKinds.applications => _applications,
      _ => throw const RemoteException(
        'unsupported',
        'This command is unavailable on Samsung TV.',
      ),
    };
  }

  @override
  Stream<Object?> subscribe(EngineOperation operation) => const Stream.empty();

  @override
  Future<void> close() async {
    _closed = true;
    await _session.close();
    _finish();
  }

  Future<void> _launch(Map<String, Object?> arguments) async {
    final id = '${arguments['target'] ?? ''}';
    if (_appId.firstMatch(id)?.end != id.length) {
      throw const RemoteException('appId', 'Enter a valid Samsung app ID.');
    }
    await _session.launch(id);
  }

  void _requireOpen() {
    if (_session.isClosed) {
      throw const RemoteException(
        'network',
        'Connect to the Samsung TV first.',
      );
    }
  }

  void _finish() {
    if (!_lost.isCompleted && !_closed) {
      _lost.complete();
    }
  }
}
