import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/data/network/services/ios_android_tv_bonjour.dart';
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
      final adapter = IosAndroidTvBonjour(channel: channel);
      try {
        await adapter.browse(DiscoveryCancellation());
        fail('The denied search should fail');
      } on DiscoveryOperationFailure catch (error) {
        final report = ProviderDiscoveryStatus(
          providerId: 'android.tv',
          status: DiscoveryStatus.failed,
          failure: DiscoveryFailure('android.tv', error),
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
      expect((await adapter.browse(DiscoveryCancellation())).single.port, 6466);
    },
  );

  test('cancellation stops only the native request that it started', () async {
    final pending = Completer<List<Object?>>();
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'browseAndroidTV') {
        return pending.future;
      }
      pending.complete([]);
      return null;
    });
    final cancellation = DiscoveryCancellation();
    final result = IosAndroidTvBonjour(channel: channel).browse(cancellation);
    cancellation.cancel();
    expect(await result, isEmpty);
    expect(calls.map((call) => call.method), [
      'browseAndroidTV',
      'cancelAndroidTV',
    ]);
    expect(calls.map((call) => call.arguments), [1, 1]);
  });
}
