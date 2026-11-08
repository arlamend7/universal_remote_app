import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/data/network/functions/parse_neighbor_address.dart';
import 'package:universal_remote_app/data/network/services/platform_hardware_address_resolver.dart';
import 'package:universal_remote_app/presentation/views/remote/viewmodels/remote_viewmodel.dart';

import '../support/fake_wake_provider.dart';
import '../support/memory_storage.dart';
import '../support/test_device.dart';

const _mac = '0a:0b:00:12:ef:03';
const _manual = 'aa:bb:cc:dd:ee:ff';
String _neighbor(String host) =>
    '? ($host) at a:b:0:12:EF:3 on en0 ifscope [ethernet]';

void main() {
  test('macOS neighbor output matches the target and rejects missing, proxy and multicast entries', () {
    const host = '192.168.1.20';
    expect(parseNeighborAddress(_neighbor(host), host), _mac);
    expect(parseNeighborAddress(_neighbor('192.168.1.1'), host), isNull);
    expect(
      parseNeighborAddress('? ($host) at (incomplete) on en0', host),
      isNull,
    );
    expect(
      parseNeighborAddress('${_neighbor(host)} published (proxy only)', host),
      isNull,
    );
    expect(
      parseNeighborAddress('? ($host) at ff:ff:ff:ff:ff:ff on en0', host),
      isNull,
    );
    expect(
      parseNeighborAddress('? ($host) at a:b:0:12:ef:3 on utun0', host),
      isNull,
    );
  });
  test(
    'unsupported platforms and non-unicast targets never run a neighbor lookup',
    () async {
      var lookups = 0;
      Future<String> lookup(String host) async {
        lookups++;
        return _neighbor(host);
      }

      final unsupported = PlatformHardwareAddressResolver(
        supported: false,
        lookup: lookup,
      );
      expect(
        await unsupported.resolve(InternetAddress('192.168.1.20')),
        isNull,
      );
      final supported = PlatformHardwareAddressResolver(
        supported: true,
        lookup: lookup,
      );
      expect(await supported.resolve(InternetAddress.loopbackIPv4), isNull);
      expect(await supported.resolve(InternetAddress('224.0.0.1')), isNull);
      expect(await supported.resolve(InternetAddress('::1')), isNull);
      expect(lookups, 0);
    },
  );
  test('successful pairing learns and persists the MAC, and wake uses it before reconnecting', () async {
    final provider = FakeWakeProvider(requiresMac: true);
    final storage = MemoryStorage();
    final registry = ProviderRegistry()..register(provider);
    final resolver = PlatformHardwareAddressResolver(
      supported: true,
      lookup: (host) async => _neighbor(host),
    );
    final app = await AppBootstrap.initialize(
      storage: storage,
      registry: registry,
      hardwareAddressResolver: resolver,
    );
    await app.savedDevices.save(
      copyDevice(tv, metadata: {'remoteLayout.v1': 'fixture-layout'}),
    );
    final learned = Completer<RemoteDevice>();
    app.savedDevices.devices.addListener(() {
      final profile = app.savedDevices.devices.value.single;
      if (profile.metadata['macAddress'] != null && !learned.isCompleted) {
        learned.complete(profile);
      }
    });
    await app.connection.connect(tv);
    final profile = await learned.future.timeout(const Duration(seconds: 1));
    expect(profile.metadata['macAddress'], _mac);
    expect(profile.metadata['macAddressSource'], 'localNeighbor');
    expect(profile.metadata['remoteLayout.v1'], 'fixture-layout');
    final model = RemoteViewModel(app);
    expect(model.canWake, isTrue);
    await app.connection.disconnect();
    await model.wake();
    expect(provider.wakeTarget?.metadata['macAddress'], _mac);
    await app.dispose();
    final reloaded = await AppBootstrap.initialize(
      storage: storage,
      registry: registry,
    );
    final restored = reloaded.savedDevices.devices.value.single;
    expect(restored.metadata['macAddress'], _mac);
    expect(reloaded.providers.canWake(restored), isTrue);
    await reloaded.dispose();
  });
  test(
    'manual address entered during lookup wins and is never overwritten',
    () async {
      final provider = FakeWakeProvider(requiresMac: true);
      final started = Completer<void>();
      final response = Completer<String>();
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..register(provider),
        hardwareAddressResolver: PlatformHardwareAddressResolver(
          supported: true,
          lookup: (_) {
            started.complete();
            return response.future;
          },
        ),
      );
      await app.connection.connect(tv);
      await started.future.timeout(const Duration(seconds: 1));
      final profile = app.savedDevices.devices.value.single;
      await app.savedDevices.save(
        copyDevice(
          profile,
          metadata: {...profile.metadata, 'macAddress': _manual},
        ),
      );
      response.complete(_neighbor(tv.endpoints.single.host));
      await Future<void>.delayed(Duration.zero);
      expect(
        app.savedDevices.devices.value.single.metadata['macAddress'],
        _manual,
      );
      expect(
        app.savedDevices.devices.value.single.metadata['macAddressSource'],
        isNull,
      );
      await app.dispose();
    },
  );
  test(
    'late lookup after forgetting a TV cannot recreate its saved profile',
    () async {
      final provider = FakeWakeProvider(requiresMac: true);
      final started = Completer<void>();
      final response = Completer<String>();
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..register(provider),
        hardwareAddressResolver: PlatformHardwareAddressResolver(
          supported: true,
          lookup: (_) {
            started.complete();
            return response.future;
          },
        ),
      );
      await app.connection.connect(tv);
      await started.future.timeout(const Duration(seconds: 1));
      await app.connection.forget(tv);
      response.complete(_neighbor(tv.endpoints.single.host));
      await Future<void>.delayed(Duration.zero);
      expect(app.savedDevices.devices.value, isEmpty);
      await app.dispose();
    },
  );
  test('TV-reported MAC works without a platform neighbor lookup', () async {
    final provider = FakeWakeProvider(requiresMac: true, wakeAddress: _mac);
    var lookups = 0;
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..register(provider),
      hardwareAddressResolver: PlatformHardwareAddressResolver(
        supported: true,
        lookup: (host) async {
          lookups++;
          return _neighbor(host);
        },
      ),
    );
    final learned = Completer<RemoteDevice>();
    app.savedDevices.devices.addListener(() {
      final profile = app.savedDevices.devices.value.single;
      if (profile.metadata['macAddress'] != null && !learned.isCompleted) {
        learned.complete(profile);
      }
    });
    await app.connection.connect(tv);
    final profile = await learned.future.timeout(const Duration(seconds: 1));
    expect(profile.metadata['macAddress'], _mac);
    expect(profile.metadata['macAddressSource'], 'television');
    expect(profile.metadata['broadcastAddress'], '192.168.1.255');
    expect(lookups, 0);
    await app.dispose();
  });
}
