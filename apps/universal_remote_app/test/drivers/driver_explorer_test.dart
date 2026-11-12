import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';
import 'package:universal_remote_app/presentation/views/drivers/driver_explorer_page.dart';

import '../support/counting_credential_store.dart';

void main() {
  testWidgets(
    'verified cached metadata opens provider, integration and capabilities',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync('driver-explorer-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final drivers = IntegrationService(
        root: directory,
        engines: ProtocolEngineRegistry([JsonWebSocketEngine()]),
        credentials: CountingCredentialStore(),
        verify: (_, _, _) async => true,
        source: DriverHttpSource(
          Uri.parse('https://unreachable.invalid/drivers/'),
        ),
      );
      await tester.runAsync(() async {
        await AtomicJsonFile(
          File('${directory.path}/catalog-cache.json'),
        ).write({'envelope': _envelope(), 'checkedAt': '2026-01-01T00:00:00Z'});
        await tester.pumpWidget(
          MaterialApp(home: DriverExplorerPage(drivers: drivers)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('Last catalog refresh'), findsOneWidget);
      await tester.tap(find.text('Example'));
      await tester.pumpAndSettle();
      expect(find.text('Integrations'), findsOneWidget);
      expect(find.textContaining('Not installed'), findsOneWidget);
      await tester.tap(find.text('Example TV 9+'));
      await tester.pumpAndSettle();
      expect(find.text('>=9'), findsOneWidget);
      expect(find.text('Example Mk II'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('mute'), 200);
      expect(find.text('Capabilities'), findsOneWidget);
      expect(find.textContaining('Conditional'), findsOneWidget);
      expect(find.textContaining('Disabled by restricted'), findsOneWidget);
    },
  );

  testWidgets('an unconfigured app shows an offline empty state', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DriverExplorerPage()));
    await tester.pumpAndSettle();
    expect(
      find.text('No verified driver catalog is available.'),
      findsOneWidget,
    );
  });
}

String _envelope() {
  const hash =
      '0f1e2d3c4b5a69788796a5b4c3d2e1f00f1e2d3c4b5a69788796a5b4c3d2e1f0';
  final payload = {
    'schemaVersion': 2,
    'revision': 3,
    'publishedAt': '2026-01-01T00:00:00Z',
    'integrations': [
      {
        'id': 'example.tv-9-plus',
        'providerId': 'example.tv',
        'name': 'Example TV 9+',
        'manufacturer': 'Example',
        'platform': 'Example OS',
        'engine': 'json-websocket',
        'channel': 'stable',
        'lastUpdatedAt': '2026-01-01T00:00:00Z',
        'requiredRuntime': {
          'api': 2,
          'operations': ['json-websocket.request'],
        },
        'compatibility': {
          'osVersion': '>=9',
          'models': ['Example Mk II'],
        },
        'profiles': [
          {'id': 'bootstrap', 'stage': 'bootstrap'},
          {
            'id': 'restricted',
            'stage': 'identified',
            'compatibility': {'firmwareVersion': '>=4'},
            'disabledCapabilities': ['volume'],
          },
        ],
        'capabilities': ['volume', 'mute'],
        'conditionalCapabilities': ['mute'],
        'package': 'packages/objects/$hash/driver.zip',
        'sha256': hash,
        'size': 1024,
        'signature': 'AQID',
      },
    ],
  };
  return jsonEncode({
    'keyId': 'fixture',
    'payload': base64Encode(utf8.encode(jsonEncode(payload))),
    'signature': 'AQID',
  });
}
