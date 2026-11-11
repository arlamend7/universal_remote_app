import 'dart:convert';

import 'package:remote_core/remote_core.dart';
import 'package:test/test.dart';

Map<String, Object?> fixture() => {
  'schemaVersion': 1,
  'id': 'example.smarttv',
  'providerId': 'example.tv',
  'version': '1.2.3',
  'name': 'Example TV',
  'manufacturer': 'Example',
  'platform': 'ExampleOS',
  'requiredRuntime': '>=1.0.0 <2.0.0',
  'operations': ['websocket.connect', 'websocket.sendJson'],
  'capabilities': ['volume'],
  'compatibility': [
    {
      'id': 'generic',
      'version': 1,
      'models': ['EX-42'],
      'firmwareVersion': 'FW_009',
    },
  ],
};

void main() {
  test(
    'driver metadata round trips with typed operation and capability IDs',
    () {
      final json = jsonDecode(jsonEncode(fixture())) as Map<String, Object?>;
      final manifest = DriverManifest.fromJson(json);
      expect(manifest.identity.providerId, 'example.tv');
      expect(manifest.identity.version, DriverVersion.parse('1.2.3'));
      expect(
        manifest.runtime.operations,
        contains(DriverOperation.webSocketConnect),
      );
      expect(manifest.capabilities, {RemoteCapability.volume});
      expect(manifest.compatibility.single.firmwareVersion, 'FW_009');
      expect(manifest.toJson(), json);
    },
  );

  test(
    'driver versions compare numeric components and reject invalid syntax',
    () {
      expect(
        DriverVersion.parse('1.10.0').compareTo(DriverVersion.parse('1.9.9')),
        1,
      );
      for (final invalid in ['1.0', '01.2.3', '1.2.3-beta', '1.2.3\n']) {
        expect(() => DriverVersion.parse(invalid), throwsFormatException);
      }
    },
  );

  test('malformed or unsupported metadata is rejected', () {
    for (final (field, invalid) in <(String, Object?)>[
      ('schemaVersion', 1.0),
      ('schemaVersion', 2),
      ('id', '../other'),
      ('requiredRuntime', '>=2.0.0 <1.0.0'),
      ('requiredRuntime', '*'),
      ('operations', ['execute.shell']),
      ('capabilities', ['untrustedCapability']),
      ('compatibility', []),
      ('allowInsecureTls', true),
    ]) {
      expect(
        () => DriverManifest.fromJson({...fixture(), field: invalid}),
        throwsFormatException,
        reason: field,
      );
    }
  });
}
