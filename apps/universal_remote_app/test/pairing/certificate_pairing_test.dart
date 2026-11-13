import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/data/network/services/platform_hardware_address_resolver.dart';
import 'package:universal_remote_app/app/app_dependencies.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:universal_remote_app/data/pairing/repositories/secure_credential_store.dart';

import '../support/lg_integration_provider.dart';
import '../support/memory_storage.dart';
import '../support/pairing_tv_transport.dart';

void main() {
  const evidence = PeerCertificate(
    derBase64: 'AQID',
    fingerprint: '01:02:03',
    subject: 'LG test TV',
  );
  for (final scenario in ['automatic', 'changed', 'no-feedback']) {
    final approveTrust = scenario != 'changed';
    final replacing = scenario == 'changed';
    testWidgets(
      'certificate review $scenario respects trust and on-TV approval',
      (tester) async {
        final storage = MemoryStorage();
        final credentials = SecureCredentialStore(storage);
        final main = PairingTvTransport(
          denyVolumeFeedback: scenario == 'no-feedback',
        );
        final pointer = PairingTvTransport()..pointer = true;
        late AppDependencies dependencies;
        var opens = 0;
        final provider = lgIntegrationProvider(
          credentials: credentials,
          connector: (Uri uri) async {
            opens++;
            final trusted = dependencies.savedDevices.devices.value.single;
            if (trusted.metadata['trustedCertificateDer'] !=
                evidence.derBase64) {
              throw const HandshakeException('CERTIFICATE_VERIFY_FAILED');
            }
            expect(uri.scheme, 'wss');
            return uri.path == '/pointer' ? pointer : main;
          },
        );
        final base = provider.manualSetup!.manualDeviceFactory(
          address: '172.16.1.13',
          name: 'LG TV',
          legacy: false,
          allowInsecurePointer: false,
        );
        final tv = replacing
            ? copyDevice(base, metadata: {'trustedCertificateDer': 'BAUG'})
            : base;
        dependencies = await AppBootstrap.initialize(
          storage: storage,
          registry: ProviderRegistry()..registerDefinition(provider),
          hardwareAddressResolver: PlatformHardwareAddressResolver(
            supported: false,
          ),
          inspectCertificate: (uri) async {
            expect(uri, tv.endpoints.single);
            return evidence;
          },
        );
        await dependencies.savedDevices.save(tv);
        if (scenario == 'no-feedback') {
          final layout = defaultRemoteGrid();
          await dependencies.grids.save(
            tv,
            layout.withItems([
              ...layout.items,
              GridItem(
                id: 'test-volume-slider',
                definitionId: 'volumeSlider',
                x: 0,
                y: 5,
                w: 4,
                h: 1,
              ),
            ]),
          );
        }
        await tester.pumpWidget(UniversalRemoteApp(dependencies: dependencies));
        await tester.tap(find.text('LG TV'));
        if (!replacing) {
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump(const Duration(milliseconds: 400));
        }
        if (replacing) {
          await tester.pumpAndSettle();
          await tester.tap(find.text('Review TV certificate and pair'));
          await tester.pumpAndSettle();
          expect(find.text('The TV certificate has changed'), findsOneWidget);
          expect(find.textContaining('172.16.1.13'), findsWidgets);
          expect(main.requests, isEmpty);
          expect(opens, 1);
          await tester.tap(find.text('Cancel'));
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        if (approveTrust) {
          expect(opens, 2);
          expect(
            dependencies.connection.state.value,
            DeviceConnectionState.pairing,
          );
          expect(
            find.text('Approve the connection on your TV'),
            findsOneWidget,
          );
          expect(await credentials.read(tv.id), isNull);
          expect(main.requests.single['type'], 'register');
          main.approve();
          await tester.pumpAndSettle();
          expect(
            dependencies.connection.state.value,
            DeviceConnectionState.connected,
          );
          expect(await credentials.read(tv.id), 'test-only-paired-key');
          await tester.ensureVisible(find.byTooltip('OK'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('OK'));
          await tester.pumpAndSettle();
          expect(pointer.frames, contains('type:button\nname:ENTER\n\n'));
          if (scenario == 'no-feedback') {
            await tester.pumpAndSettle();
            expect(
              tester.widget<Slider>(find.byType(Slider)).onChanged,
              isNull,
            );
            expect(find.byTooltip('Louder'), findsOneWidget);
            expect(
              dependencies.connection.supports(RemoteCapability.volume),
              isTrue,
            );
          }

          await dependencies.connection
              .tvWith(RemoteCapability.volume)!
              .volumeUp();
          expect(main.requests.last['uri'], 'ssap://audio/volumeUp');
          expect(dependencies.connection.selected.value!.id, tv.id);
          expect(
            dependencies.connection.selected.value!.endpoints.single.scheme,
            'wss',
          );
        } else {
          expect(opens, 1);
          expect(main.requests, isEmpty);
          expect(await credentials.read(tv.id), isNull);
          expect(
            dependencies
                .savedDevices
                .devices
                .value
                .single
                .metadata['trustedCertificateDer'],
            replacing ? 'BAUG' : isNull,
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
      },
    );
  }
}
