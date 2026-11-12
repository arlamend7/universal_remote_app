import 'dart:convert';

import 'package:remote_driver_runtime/ssap.dart';

/// A small SSAP integration whose JSON each test can edit.
Map<String, Object?> ssapManifest({
  List<String> capabilities = const ['volume', 'mute', 'inputs'],
  List<Map<String, Object?>> profiles = const [
    {'id': 'bootstrap', 'stage': 'bootstrap'},
    {
      'id': 'modern',
      'stage': 'identified',
      'compatibility': {'osVersion': '>=7'},
      'mappingOverrides': {
        'volume-up': {
          'kind': 'ssap.request',
          'uri': 'ssap://audio/volumeUpModern',
        },
      },
    },
  ],
}) => {
  'schemaVersion': 2,
  'integrationId': 'test.ssap',
  'providerId': 'test.ssap',
  'name': 'Test SSAP',
  'manufacturer': 'Test',
  'platform': 'Test OS',
  'engine': 'ssap',
  'requiredRuntime': {
    'api': 2,
    'operations': ['ssap.request', 'ssap.pointer-button'],
  },
  'compatibility': {'versionScheme': 'dotted-numeric'},
  'profiles': profiles,
  'capabilities': capabilities,
};

Map<String, Object?> ssapMappings({
  String volumeUp = 'ssap://audio/volumeUp',
}) => {
  'volume-up': {'kind': 'ssap.request', 'uri': volumeUp},
  'volume-down': {'kind': 'ssap.request', 'uri': 'ssap://audio/volumeDown'},
  'set-mute': {
    'kind': 'ssap.request',
    'uri': 'ssap://audio/setMute',
    'payload': {
      'mute': {r'$argument': 'muted'},
    },
  },
  'read-volume': {
    'kind': 'ssap.request',
    'uri': 'ssap://audio/getVolume',
    'result': 'volume',
    'readOnly': true,
  },
  'list-inputs': {
    'kind': 'ssap.request',
    'uri': 'ssap://tv/getExternalInputList',
    'result': 'inputs',
  },
  'select-input': {
    'kind': 'ssap.request',
    'uri': 'ssap://tv/switchInput',
    'payload': {
      'inputId': {r'$argument': 'target'},
    },
  },
  'key-mute': {'kind': 'ssap.pointer-button', 'button': 'MUTE'},
};

Map<String, Object?> ssapCapabilities() => {
  'volume': {
    'alternatives': [
      ['volume-up', 'volume-down'],
    ],
  },
  'mute': {
    'alternatives': [
      ['set-mute', 'read-volume'],
      ['key-mute'],
    ],
    'disableOn': ['unsupported', 'permission'],
  },
  'inputs': {
    'alternatives': [
      ['list-inputs', 'select-input'],
    ],
    'verify': {
      'operation': 'list-inputs',
      'expect': 'non-empty',
      'availability': 'known',
    },
  },
};

Map<String, String> ssapFiles({
  Map<String, Object?>? manifest,
  Map<String, Object?>? mappings,
  Map<String, Object?>? capabilities,
}) => {
  'manifest.json': jsonEncode(manifest ?? ssapManifest()),
  'mappings.json': jsonEncode(mappings ?? ssapMappings()),
  'capabilities.json': jsonEncode(capabilities ?? ssapCapabilities()),
  'connection.json': jsonEncode({
    'registration': defaultLgManifest,
    'allowLegacyTransport': true,
  }),
};
