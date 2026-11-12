import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/data/network/services/ios_bonjour.dart';
import 'package:universal_remote_app/domains/discovery/functions/discovery_diagnostic_fields.dart';
import 'package:universal_remote_app/domains/discovery/functions/discovery_failure_message.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/ios-bonjour');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'denial preserves stage and DNS error, and a fresh search can recover',
    () async {
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (_) async {
        if (++calls == 1) {
          throw PlatformException(
            code: 'localNetworkDenied',
            details: {
              'stage': 'bonjour.browse',
              'domain': 'dns',
              'osCode': -65570,
            },
          );
        }
        return [
          {'name': 'Living Room', 'address': '192.168.1.12', 'port': 6466},
        ];
      });
      final adapter = IosBonjour(channel: channel);
      try {
        await adapter.browse(
          DiscoveryCancellation(),
          service: '_androidtvremote2._tcp',
        );
        fail('The denied search should fail');
      } on DiscoveryOperationFailure catch (error) {
        final report = ProtocolDiscoveryStatus(
          protocolId: DiscoveryProtocol.bonjour,
          status: DiscoveryStatus.failed,
          failure: DiscoveryFailure(DiscoveryProtocol.bonjour, error),
        );
        expect(
          discoveryDiagnosticFields(report),
          containsPair('stage', 'bonjour.browse'),
        );
        expect(
          discoveryDiagnosticFields(report),
          containsPair('osCode', -65570),
        );
        expect(
          discoveryDiagnosticFields(report),
          containsPair('code', 'localNetworkDenied'),
        );
        expect(discoveryFailureMessage(error), contains('Enable it'));
      }
      expect(
        (await adapter.browse(
          DiscoveryCancellation(),
          service: '_androidtvremote2._tcp',
        )).single.port,
        6466,
      );
    },
  );

  test('cancellation stops only the native request that it started', () async {
    final pending = Completer<List<Object?>>();
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'browseBonjour') {
        return pending.future;
      }
      pending.complete([]);
      return null;
    });
    final cancellation = DiscoveryCancellation();
    final result = IosBonjour(channel: channel)
        .browse(cancellation, service: '_androidtvremote2._tcp');
    cancellation.cancel();
    expect(await result, isEmpty);
    expect(calls.map((call) => call.method), [
      'browseBonjour',
      'cancelBonjour',
    ]);
    expect(calls.first.arguments, {
      'id': 1,
      'service': '_androidtvremote2._tcp',
    });
    expect(calls.last.arguments, 1);
  });

  test(
    'native TXT entries reach the observation as bounded metadata',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => [
          {
            'name': 'Living Room',
            'address': '192.168.1.12',
            'port': 6466,
            'txt': ['bt=AA:BB:CC:DD:EE:FF', 'name=spoofed', 7, 'bad key=1'],
          },
          {'name': 'Bedroom', 'address': '192.168.1.13', 'port': 6466},
        ],
      );
      final observations = <DiscoveryObservation>[];
      await IosBonjour(channel: channel).search(
        '_androidtvremote2._tcp',
        DiscoveryCancellation(),
        (observation) async => observations.add(observation),
      );
      expect(observations.first.metadata, {
        'txt.bt': 'AA:BB:CC:DD:EE:FF',
        'txt.name': 'spoofed',
        'name': 'Living Room',
      });
      expect(observations.last.metadata, {'name': 'Bedroom'});
    },
  );
}
