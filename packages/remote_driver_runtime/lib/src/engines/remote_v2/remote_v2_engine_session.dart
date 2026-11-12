import 'dart:async';
import 'dart:io';

import 'package:remote_core/remote_core.dart';

import '../../remote_v2/protocol/android_app_links.dart';
import '../../remote_v2/protocol/android_device_info.dart';
import '../../remote_v2/protocol/android_pairing.dart';
import '../../remote_v2/protocol/android_remote_session.dart';
import '../../remote_v2/security/client_identity.dart';
import '../../remote_v2/security/paired_identity.dart';
import '../common/transport_connection_error.dart';
import '../contracts/content_reading.dart';
import '../contracts/engine_operation.dart';
import '../contracts/engine_session.dart';
import '../contracts/engine_session_context.dart';
import 'remote_v2_kinds.dart';
import 'remote_v2_operation.dart';

/// A pinned-TLS Remote v2 session. Pairing exchanges certificates once; the
/// stored identity is reused and the TV certificate must keep matching.
final class RemoteV2EngineSession implements EngineSession {
  RemoteV2EngineSession._(this._session, this._identity, this._software) {
    _audio = _audioFacts();
    _volumes = _session.volumes.listen(_volumeChanged);
  }

  /// Socket and timeout failures become typed connection errors (for example
  /// `connectionRefused`), so wake-and-retry and fallback policies can act on
  /// them. Protocol, pairing and certificate errors pass through unchanged.
  static Future<RemoteV2EngineSession> open(
    EngineSessionContext context, {
    int? portOverride,
    int? pairingPortOverride,
  }) async {
    try {
      return await _open(context, portOverride, pairingPortOverride);
    } on SocketException catch (error, stack) {
      Error.throwWithStackTrace(transportConnectionError(error), stack);
    } on TimeoutException catch (error, stack) {
      Error.throwWithStackTrace(transportConnectionError(error), stack);
    }
  }

  static Future<RemoteV2EngineSession> _open(
    EngineSessionContext context,
    int? portOverride,
    int? pairingPortOverride,
  ) async {
    final endpoint = context.device.endpoints.single;
    final stored = await context.credentials.read(context.credentialKey);
    final identity = stored == null
        ? await _pair(context, endpoint.host, pairingPortOverride)
        : PairedIdentity.decode(stored);
    final session = AndroidRemoteSession(
      endpoint.host,
      identity,
      port: portOverride ?? context.connection['port']! as int,
    );
    final closed = Completer<void>();
    try {
      await session.connect(() {
        if (!closed.isCompleted) {
          closed.complete();
        }
      });
    } catch (_) {
      session.close();
      rethrow;
    }
    final result = RemoteV2EngineSession._(
      session,
      identity,
      _describe(session.deviceInfo, context.connection),
    );
    unawaited(closed.future.then((_) => result._finish()));
    return result;
  }

  /// Remote v2 reports vendor and model but never the Android OS version,
  /// firmware or build, so those stay unknown. The Remote Service's own
  /// package and version are kept as raw evidence only: they describe the
  /// service, not the TV software.
  static DeviceSoftwareInformation _describe(
    AndroidDeviceInfo? info,
    Map<String, Object?> connection,
  ) => DeviceSoftwareInformation(
    source: DeviceInformationSource.authenticatedSession,
    manufacturer: info?.vendor,
    model: info?.model,
    operatingSystem: connection['operatingSystem'] as String?,
    protocolVersion: 'Remote v2',
    identifiedAt: DateTime.now(),
    raw: {
      if (info?.packageName case final package?)
        'remoteServicePackage': package,
      if (info?.appVersion case final version?) 'remoteServiceVersion': version,
    },
  );

  static Future<PairedIdentity> _pair(
    EngineSessionContext context,
    String host,
    int? port,
  ) async {
    final client = await ClientIdentity.generate();
    final pairing = port == null
        ? AndroidPairing(host, client)
        : AndroidPairing(host, client, port: port);
    try {
      final identity = await pairing.run(() {
        context.onState(DeviceConnectionState.pairing);
        context.onPairingCode?.call((code) async => pairing.submit(code));
      });
      await context.credentials.write(context.credentialKey, identity.encode());
      return identity;
    } finally {
      context.onPairingCode?.call(null);
      pairing.close();
    }
  }

  final AndroidRemoteSession _session;
  final PairedIdentity _identity;
  final DeviceSoftwareInformation _software;
  late final StreamSubscription<VolumeState> _volumes;
  final _factChanges = StreamController<void>.broadcast();
  final _lost = Completer<void>();
  late Map<String, String> _audio;
  bool _closed = false;

  @override
  Map<String, String> get facts => {
    'feature.keys': '${_session.supportsKeys}',
    'feature.volume-keys': '${_session.supportsVolumeKeys}',
    'feature.power': '${_session.supportsPower}',
    'feature.ime': '${_session.supportsIme}',
    'feature.app-links': '${_session.supportsAppLinks}',
    ..._audio,
  };

  @override
  Stream<void> get factChanges => _factChanges.stream;
  @override
  DeviceSoftwareInformation? get software => _software;
  @override
  String? get verifiedPeerIdentity => _identity.fingerprint;
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
    final call = operation as RemoteV2Operation;
    return switch (call.kind) {
      RemoteV2Kinds.key => _session.key(call.code),
      RemoteV2Kinds.text => _session.text('${arguments['text'] ?? ''}'),
      RemoteV2Kinds.submit => _session.submit(),
      RemoteV2Kinds.appLink => _launch(arguments),
      RemoteV2Kinds.setVolume => _session.setVolume(
        arguments['volume']! as int,
      ),
      RemoteV2Kinds.setMute => _session.setMuted(arguments['muted']! as bool),
      RemoteV2Kinds.readVolume => _session.volume ?? _unsupported(),
      RemoteV2Kinds.readContent => _content(),
      _ => _unsupported(),
    };
  }

  @override
  Stream<Object?> subscribe(EngineOperation operation) =>
      switch (operation.kind) {
        RemoteV2Kinds.volume => _session.volumes,
        RemoteV2Kinds.content => _session.contents.map(ContentReading.new),
        _ => const Stream.empty(),
      };

  @override
  Future<void> close() async {
    _closed = true;
    _session.close();
    await _finish();
  }

  Future<void> _launch(Map<String, Object?> arguments) async {
    final link = androidAppLink('${arguments['target'] ?? ''}');
    if (link == null || !_session.supportsAppLinks) {
      throw const RemoteException(
        'appLink',
        'Enter an Android package id, such as com.example.tv, or a supported app link such as vnd.youtube:// or an HTTPS link.',
      );
    }
    await _session.launchLink(link);
  }

  Future<ContentReading> _content() async {
    final content = _session.content;
    if (content == null) {
      return _unsupported();
    }
    return ContentReading(content);
  }

  Map<String, String> _audioFacts() => {
    'volume.reported': '${_session.volume != null}',
    'audio.absolute': '${_session.supportsAbsoluteVolume}',
    'audio.adjustable': '${_session.supportsMute}',
  };

  void _volumeChanged(VolumeState _) {
    final next = _audioFacts();
    final changed = next.entries.any(
      (entry) => _audio[entry.key] != entry.value,
    );
    _audio = next;
    if (changed && !_factChanges.isClosed) {
      _factChanges.add(null);
    }
  }

  Future<void> _finish() async {
    if (!_lost.isCompleted && !_closed) {
      _lost.complete();
    }
    await _volumes.cancel();
    if (!_factChanges.isClosed) {
      await _factChanges.close();
    }
  }

  static Future<Never> _unsupported() => Future.error(
    const RemoteException(
      'unsupported',
      'This command is unavailable on the connected TV.',
    ),
  );
}
