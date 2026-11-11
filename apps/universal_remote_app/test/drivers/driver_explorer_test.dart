import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:universal_remote_app/presentation/views/drivers/driver_explorer_page.dart';

void main() {
  testWidgets(
    'verified metadata opens provider, versions and capabilities offline',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync('driver-explorer-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final storage = DriverPackageStorage(directory);
      final source = DriverHttpSource(
        Uri.parse('https://unreachable.invalid/drivers/'),
      );
      final catalogs = DriverCatalogRepository(
        source,
        storage,
        (_, _, _) async => true,
      );
      await tester.runAsync(() async {
        await storage.writeCatalog(
          CachedDriverCatalog(_catalog(), checkedAt: DateTime.utc(2026, 1, 1)),
        );
        final page = DriverExplorerPage(catalogs: catalogs);
        await tester.pumpWidget(MaterialApp(home: page));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.text('Last catalog refresh'), findsOneWidget);
      await tester.tap(find.text('Example TV'));
      await tester.pumpAndSettle();
      expect(find.text('Versions'), findsOneWidget);
      expect(find.textContaining('Example release notes'), findsOneWidget);
      await tester.tap(find.text('1.0.0'));
      await tester.pumpAndSettle();
      expect(find.text('Capabilities'), findsOneWidget);
      expect(find.text('volume'), findsOneWidget);
      expect(find.textContaining('Declared by the driver'), findsOneWidget);
      expect(find.textContaining('Disabled for restricted'), findsOneWidget);
      expect(find.textContaining('Firmware >=04.00.00'), findsOneWidget);
      expect(find.text('No catalog declaration'), findsWidgets);
    },
  );

  testWidgets('unconfigured app shows an offline catalog empty state', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: DriverExplorerPage()));
    await tester.pumpAndSettle();
    expect(
      find.text('No verified driver catalog is available.'),
      findsOneWidget,
    );
  });
}

String _catalog() {
  final manifest = {
    'schemaVersion': 1,
    'id': 'example.smarttv',
    'providerId': 'example.tv',
    'version': '1.0.0',
    'name': 'Example TV',
    'manufacturer': 'Example',
    'platform': 'ExampleOS',
    'requiredRuntime': '>=1.0.0',
    'operations': ['websocket.connect'],
    'capabilities': ['volume'],
    'compatibility': [
      {'id': 'generic', 'version': 1, 'models': <String>[]},
      {
        'id': 'restricted',
        'version': 2,
        'models': ['Example Mk II'],
        'firmwareVersion': '>=04.00.00',
        'disabledCapabilities': ['volume'],
      },
    ],
  };
  final payload = {
    'schemaVersion': 1,
    'revision': 1,
    'publishedAt': '2026-01-01T00:00:00Z',
    'releases': [
      {
        'manifest': manifest,
        'package': 'packages/example.smarttv/1.0.0/driver.zip',
        'size': 1,
        'sha256': 'a' * 64,
        'signature': 'AQ==',
        'channel': 'stable',
        'notes': 'Example release notes',
        'publishedAt': '2026-01-01T00:00:00Z',
      },
    ],
  };
  return jsonEncode({
    'keyId': 'fixture',
    'payload': base64Encode(utf8.encode(jsonEncode(payload))),
    'signature': 'AQ==',
  });
}
