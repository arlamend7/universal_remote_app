import 'dart:convert';
import 'dart:typed_data';

import 'package:remote_driver_manager/remote_driver_manager.dart';

import 'stored_zip_writer.dart';

/// Builds signed catalog entries and packages for one example integration.
final class IntegrationFixture {
  IntegrationFixture(this.sign, {this.keyId = 'fixture-key'});

  final Future<Uint8List> Function(List<int> bytes) sign;
  final String keyId;
  int revision = 1;

  static Map<String, Object?> manifest({
    String lastUpdatedAt = '2026-11-11T21:25:00Z',
    String integrationId = 'example.json-websocket',
    List<String> profiles = const ['bootstrap'],
  }) => {
    'schemaVersion': 2,
    'integrationId': integrationId,
    'providerId': 'example.smarttv',
    'name': 'Example TV',
    'manufacturer': 'Example',
    'platform': 'Example OS',
    'engine': 'json-websocket',
    'lastUpdatedAt': lastUpdatedAt,
    'requiredRuntime': {
      'api': 2,
      'operations': ['json-websocket.request'],
    },
    'compatibility': {'versionScheme': 'dotted-numeric'},
    'profiles': [
      for (final (index, id) in profiles.indexed)
        {'id': id, 'stage': index == 0 ? 'bootstrap' : 'identified'},
    ],
    'capabilities': ['volume'],
    'replaces': ['example-tv'],
  };

  static Uint8List package({
    String lastUpdatedAt = '2026-11-11T21:25:00Z',
    String command = 'volumeUp',
    List<String> profiles = const ['bootstrap'],
  }) => storedZip({
    'manifest.json': jsonEncode(
      manifest(lastUpdatedAt: lastUpdatedAt, profiles: profiles),
    ),
    'capabilities.json': jsonEncode({
      'volume': {
        'alternatives': [
          ['volume-up', 'volume-down'],
        ],
      },
    }),
    'mappings.json': jsonEncode({
      'volume-up': {'kind': 'json-websocket.request', 'command': command},
      'volume-down': {
        'kind': 'json-websocket.request',
        'command': 'volumeDown',
      },
    }),
  });

  Future<Map<String, Object?>> entry(
    Uint8List bytes, {
    String lastUpdatedAt = '2026-11-11T21:25:00Z',
    String channel = 'stable',
  }) async {
    final hash = IntegrationPackage.digest(bytes);
    final json = manifest(lastUpdatedAt: lastUpdatedAt);
    return {
      'id': json['integrationId'],
      'providerId': json['providerId'],
      'name': json['name'],
      'manufacturer': json['manufacturer'],
      'platform': json['platform'],
      'engine': json['engine'],
      'channel': channel,
      'lastUpdatedAt': lastUpdatedAt,
      'requiredRuntime': json['requiredRuntime'],
      'compatibility': json['compatibility'],
      'profiles': json['profiles'],
      'capabilities': json['capabilities'],
      'package': CatalogIntegration.objectPath(hash),
      'sha256': hash,
      'size': bytes.length,
      'signature': base64Encode(await sign(bytes)),
      'replaces': json['replaces'],
    };
  }

  Future<String> envelope(List<Map<String, Object?>> integrations) async {
    final payload = utf8.encode(
      jsonEncode({
        'schemaVersion': 2,
        'revision': revision,
        'publishedAt': '2026-11-11T21:30:00Z',
        'integrations': integrations,
      }),
    );
    return jsonEncode({
      'keyId': keyId,
      'payload': base64Encode(payload),
      'signature': base64Encode(await sign(payload)),
    });
  }
}
