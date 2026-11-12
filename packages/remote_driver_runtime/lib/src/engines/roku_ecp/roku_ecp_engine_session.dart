import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:xml/xml.dart';

import '../../ecp/roku_ecp_client.dart';
import '../contracts/content_reading.dart';
import '../contracts/engine_operation.dart';
import '../contracts/engine_session.dart';
import '../contracts/engine_session_context.dart';
import 'decoders/ecp_application_catalog.dart';
import 'decoders/ecp_fields.dart';
import 'decoders/ecp_launch_link.dart';
import 'decoders/ecp_serial.dart';
import 'roku_ecp_kinds.dart';

/// A stateless ECP device identified by its serial number; every command
/// is a bounded local HTTP request.
final class RokuEcpEngineSession implements EngineSession {
  RokuEcpEngineSession._(
    this._client,
    this._serial,
    this._catalog,
    this._facts,
    this._software,
  );

  static Future<RokuEcpEngineSession> open(
    EngineSessionContext context,
    RokuEcpClient client,
  ) async {
    final info = await client.query('device-info');
    final serial = rokuSerial(info);
    if (serial == null) {
      throw const RemoteException(
        'protocol',
        'The device did not report a Roku identity.',
      );
    }
    _requireExpected(context.device, serial);
    final isTv = info.getElement('is-tv')?.innerText == 'true';
    final keys = (context.connection['inputKeys']! as Map)
        .cast<String, String>();
    final catalogRequest = _loadCatalog(client, keys);
    final content = await _optional(() => client.query('active-app'));
    final channels = isTv
        ? await _optional(() => client.query('tv-channels'))
        : null;
    final catalog = await catalogRequest;
    final listed = channels == null
        ? const <DeviceChannel>[]
        : rokuChannels(channels);
    return RokuEcpEngineSession._(client, serial, catalog, {
      'device.is-tv': '$isTv',
      ..._flags(info),
      'catalog.applications': '${catalog?.apps.isNotEmpty == true}',
      'catalog.inputs': '${isTv && catalog?.inputs.isNotEmpty == true}',
      'tuner.channels': '${listed.isNotEmpty}',
      'content.reported': '${_validContent(content)}',
    }, _identify(info, context.connection['operatingSystem'] as String?));
  }

  final RokuEcpClient _client;
  final String _serial;
  final EcpApplicationCatalog? _catalog;
  final Map<String, String> _facts;
  final DeviceSoftwareInformation _software;
  final _lost = Completer<void>();

  @override
  Map<String, String> get facts => Map.unmodifiable(_facts);
  @override
  Stream<void> get factChanges => const Stream.empty();
  @override
  DeviceSoftwareInformation? get software => _software;
  @override
  String? get verifiedPeerIdentity => null;
  @override
  String? get reportedDiscoveryIdentity => 'uuid:roku:ecp:$_serial';
  @override
  Stream<Set<String>> get unavailable => const Stream.empty();
  @override
  Future<void> get lost => _lost.future;

  @override
  Future<Object?> execute(
    EngineOperation operation,
    Map<String, Object?> arguments,
  ) async => switch (operation.kind) {
    RokuEcpKinds.key => _client.key(operation.describe()['key']! as String),
    RokuEcpKinds.text => _text('${arguments['text'] ?? ''}'),
    RokuEcpKinds.launch => _launch('${arguments['target'] ?? ''}'),
    RokuEcpKinds.applications => _catalog?.apps.toList() ?? const [],
    RokuEcpKinds.inputs => _catalog?.inputs.toList() ?? const [],
    RokuEcpKinds.selectInput => _selectInput('${arguments['target'] ?? ''}'),
    RokuEcpKinds.channels => rokuChannels(await _client.query('tv-channels')),
    RokuEcpKinds.readContent => _content(),
    RokuEcpKinds.playback => _playback(),
    _ => _unsupported(),
  };

  @override
  Stream<Object?> subscribe(EngineOperation operation) => const Stream.empty();

  @override
  Future<void> close() async {}

  Future<void> _text(String text) async {
    final runes = text.runes.take(257).toList();
    if (runes.length > 256) {
      throw const RemoteException(
        'text',
        'Send up to 256 characters at a time.',
      );
    }
    for (final rune in runes) {
      await _client.key('Lit_${String.fromCharCode(rune)}');
    }
  }

  Future<void> _launch(String target) async {
    final link = EcpLaunchLink.parse(target);
    final reported = _catalog?.apps.any((app) => app.id == link?.id) == true;
    if (link == null || !reported) {
      await _unsupported();
    }
    await _client.launch(link.id, parameters: link.parameters);
  }

  Future<void> _selectInput(String id) async {
    final key = _catalog?.keyForInput(id);
    if (key == null) {
      await _unsupported();
    }
    await _client.key(key);
  }

  Future<ContentReading> _content() async {
    final root = await _client.query('active-app');
    final app = root.getElement('app');
    final name = app?.innerText.trim();
    if (root.name.local != 'active-app' || name == null || name.isEmpty) {
      throw const RemoteException(
        'protocol',
        'Roku did not report the current app.',
      );
    }
    final id = app?.getAttribute('id') ?? 'roku.home';
    final input = _catalog?.inputs.where((input) => input.id == id).firstOrNull;
    return ContentReading(
      await _activity(id, name),
      input: input,
      reportsInput: true,
    );
  }

  Future<CurrentContent> _activity(String appId, String name) async {
    final tuner = _facts['tuner.channels'] == 'true'
        ? await _optional(() => _client.query('tv-active-channel'))
        : null;
    final channel = tuner?.getElement('channel');
    if (rokuField(channel, 'active-input') == 'true') {
      return CurrentContent(
        appId: appId,
        appName: name,
        liveTv: true,
        channelNumber: rokuField(channel, 'number'),
        channelName: rokuField(channel, 'name'),
        programTitle: rokuField(channel, 'program-title'),
      );
    }
    final player = await _optional(() => _client.query('media-player'));
    final playerApp = player?.getElement('plugin')?.getAttribute('id');
    if (player == null || player.name.local != 'player' || playerApp != appId) {
      return CurrentContent(appId: appId, appName: name);
    }
    return CurrentContent(
      appId: appId,
      appName: name,
      position: rokuMediaTime(player, 'position'),
      duration: rokuMediaTime(player, 'duration'),
    );
  }

  Future<bool?> _playback() async {
    final player = await _optional(() => _client.query('media-player'));
    if (player == null || player.name.local != 'player') {
      return null;
    }
    return switch (player.getAttribute('state')) {
      'play' => true,
      'pause' => false,
      _ => null,
    };
  }

  static void _requireExpected(RemoteDevice device, String serial) {
    final expected =
        device.metadata['rokuSerial'] ??
        device.metadata[DeviceMetadataKeys.discoveryIdentity]?.split(':').last;
    if (expected != null && expected.toLowerCase() != serial.toLowerCase()) {
      throw const RemoteException(
        'identity',
        'This address belongs to a different Roku.',
      );
    }
  }

  static Future<EcpApplicationCatalog?> _loadCatalog(
    RokuEcpClient client,
    Map<String, String> keys,
  ) async {
    final root = await _optional(() => client.query('apps'));
    if (root == null || root.name.local != 'apps') {
      return null;
    }
    return EcpApplicationCatalog(root, client.endpoint, keys);
  }

  /// Device-info control flags, only when the device states them.
  static Map<String, String> _flags(XmlElement info) => {
    for (final name in const [
      'supports-audio-volume-control',
      'supports-tv-power-control',
    ])
      if (info.getElement(name)?.innerText.trim() case final value?
          when value == 'true' || value == 'false')
        'device.$name': value,
  };

  static bool _validContent(XmlElement? root) {
    final name = root?.getElement('app')?.innerText.trim();
    return root?.name.local == 'active-app' && name != null && name.isNotEmpty;
  }

  static DeviceSoftwareInformation _identify(
    XmlElement info,
    String? operatingSystem,
  ) {
    final fields = {
      for (final name in const [
        'vendor-name',
        'model-name',
        'model-number',
        'software-version',
        'software-build',
        'is-tv',
      ])
        if (rokuField(info, name) case final value?) name: value,
    };
    return DeviceSoftwareInformation(
      source: DeviceInformationSource.protocolResponse,
      manufacturer: fields['vendor-name'],
      model: fields['model-name'],
      hardwareModel: fields['model-number'],
      operatingSystem: operatingSystem,
      operatingSystemVersion: fields['software-version'],
      buildNumber: fields['software-build'],
      identifiedAt: DateTime.now(),
      raw: fields,
    );
  }

  static Future<XmlElement?> _optional(
    Future<XmlElement> Function() query,
  ) async {
    try {
      return await query();
    } on RemoteException {
      return null;
    }
  }

  static Future<Never> _unsupported() => Future.error(
    const RemoteException(
      'unsupported',
      'This control is unavailable on the Roku.',
    ),
  );
}
