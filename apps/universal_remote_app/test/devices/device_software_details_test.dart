import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

void main() {
  testWidgets(
    'device software distinguishes live data from saved driver metadata',
    (tester) async {
      final cached = DeviceSoftwareInformation(
        source: DeviceInformationSource.authenticatedSession,
        firmwareVersion: '04.01.00',
      );
      final device = RemoteDevice(
        id: 'tv',
        name: 'TV',
        providerId: 'lg.webos',
        softwareInformation: cached,
        metadata: {
          'managedDriverVersion': '1.1.0',
          'managedDriverProfile': 'existing-webos',
        },
      );
      final live = DeviceSoftwareInformation(
        source: DeviceInformationSource.authenticatedSession,
        firmwareVersion: '04.02.00',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeviceSoftwareDetails(device: device),
            ),
          ),
        ),
      );
      expect(find.text('Saved information'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeviceSoftwareDetails(device: device, live: live),
            ),
          ),
        ),
      );
      expect(find.text('Reported during this connection'), findsOneWidget);
      await tester.tap(find.text('Device software'));
      await tester.pumpAndSettle();
      expect(find.text('04.02.00'), findsOneWidget);
      expect(find.text('04.01.00'), findsNothing);
      expect(find.text('1.1.0'), findsOneWidget);
      expect(find.text('existing-webos'), findsOneWidget);
      expect(find.text('Unknown'), findsWidgets);
    },
  );
}
