import 'package:remote_core/remote_core.dart';
import 'package:test/test.dart';

import 'support/test_controller.dart';
import 'support/test_device.dart';
import 'support/test_provider.dart';

void main() {
  test(
    'wake workflow wakes once and retries only failures the provider allows',
    () async {
      final events = <String>[];
      const workflow = DeviceConnectionWorkflow(retryDelay: Duration.zero);
      await workflow.run(
        wake: () async {
          events.add('wake');
        },
        connect: () async {
          events.add('connect');
          if (events.length == 2) {
            throw const RemoteException('starting', 'Device is starting.');
          }
        },
        isCurrent: () => true,
        canRetry: (error) =>
            error is RemoteException && error.code == 'starting',
        reset: () async {
          events.add('reset');
        },
      );
      expect(events, ['wake', 'connect', 'reset', 'connect']);
    },
  );

  test('models copy capability metadata and typed resolution is optional', () {
    final caps = {RemoteCapability.volume};
    final tv = RemoteDevice(id: 'id', name: 'TV', capabilities: caps);
    caps.clear();
    expect(tv.capabilities, {RemoteCapability.volume});
    expect(() => tv.capabilities.clear(), throwsUnsupportedError);
    final client = TestController(tv);
    expect(client.supports(RemoteCapability.volume), isTrue);
    expect(client.supports(RemoteCapability.navigation), isFalse);
    expect(() => RemoteDevice(id: '', name: 'TV'), throwsArgumentError);
  });
  test('registry rejects duplicate IDs and selects matching provider', () {
    final registry = ProviderRegistry()..register(TestProvider('one', []));
    expect(
      () => registry.register(TestProvider('one', [])),
      throwsArgumentError,
    );
    expect(registry.providerFor(device('one')).id, 'one');
    expect(
      () => registry.providerFor(device('missing')),
      throwsA(isA<RemoteException>()),
    );
  });
  test(
    'discovery isolates failures and deduplicates stable identities',
    () async {
      final tv = device('one');
      final registry = ProviderRegistry()
        ..register(TestProvider('one', [tv, tv]))
        ..register(TestProvider('broken', [], fail: true));
      final result = await registry.discover();
      expect(result.devices, hasLength(1));
      expect(result.failures.single.providerId, 'broken');
    },
  );
  test(
    'discovery publishes a fast provider while another is pending',
    () async {
      final cancellation = DiscoveryCancellation();
      final tv = device('fast');
      final hanging = TestProvider('slow', [], hang: true);
      final registry = ProviderRegistry()
        ..register(hanging)
        ..register(TestProvider('fast', [tv, tv]));
      final result = await registry.discover(
        cancellation: cancellation,
        onDevices: (found) {
          expect(found, [tv]);
          expect(hanging.token!.isCancelled, isFalse);
          cancellation.cancel();
        },
      );
      expect(result.devices, [tv]);
      expect(hanging.token!.isCancelled, isTrue);
    },
  );
  test('discovery timeout signals provider cancellation', () async {
    final hanging = TestProvider('slow', [], hang: true);
    final result = await (ProviderRegistry()..register(hanging)).discover(
      timeout: const Duration(milliseconds: 20),
    );
    expect(result.failures, hasLength(1));
    expect(hanging.token!.isCancelled, isTrue);
  });
  test(
    'parent cancellation completes discovery and releases provider',
    () async {
      final cancellation = DiscoveryCancellation();
      final hanging = TestProvider('slow', [], hang: true);
      final result = (ProviderRegistry()..register(hanging)).discover(
        cancellation: cancellation,
      );
      cancellation.cancel();
      expect((await result).devices, isEmpty);
      expect(hanging.token!.isCancelled, isTrue);
    },
  );
}
