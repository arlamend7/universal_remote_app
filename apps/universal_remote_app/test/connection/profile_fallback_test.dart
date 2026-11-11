import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/domains/connection/services/connection_controller.dart';
import 'package:universal_remote_app/domains/diagnostics/services/diagnostic_logger.dart';

import '../support/fake_provider.dart';
import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  test(
    'driver preparation runs before controller creation and cancels',
    () async {
      final provider = FakeProvider();
      final registry = ProviderRegistry()
        ..registerDefinition(provider.definition);
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: registry,
      );
      addTearDown(app.dispose);
      final entered = Completer<void>();
      final connection = ConnectionController(
        registry,
        app.savedDevices,
        DiagnosticLogger(),
        beforeConnecting: (_, cancelled, cancellation) async {
          entered.complete();
          await cancellation.first;
          expect(cancelled(), isTrue);
        },
      );
      addTearDown(connection.dispose);
      final connecting = connection.connect(tv);
      await entered.future;
      expect(provider.last, isNull);
      await connection.disconnect();
      await connecting;
      expect(provider.last, isNull);
      expect(connection.state.value, DeviceConnectionState.disconnected);
    },
  );

  for (final failure in ['network', 'tls']) {
    test(
      'linked profile fallback is bounded and excludes $failure when unsafe',
      () async {
        final primary = FakeProvider(
          startupFailure: RemoteException(failure, 'Failed'),
        );
        final alternative = FakeProvider(providerId: 'alternative');
        final app = await AppBootstrap.initialize(
          storage: MemoryStorage(),
          registry: ProviderRegistry()
            ..registerDefinition(primary.definition)
            ..registerDefinition(alternative.definition),
        );
        final second = RemoteDevice(
          id: 'second',
          name: 'TV',
          providerId: alternative.id,
          category: DeviceCategory.television,
          endpoints: tv.endpoints,
        );
        await app.savedDevices.save(tv);
        await app.savedDevices.save(second);
        await app.savedDevices.associate(tv.id, second.id);
        await app.savedDevices.credentials.write(
          second.id,
          'existing-authorization',
        );

        await app.connection.connect(tv);
        if (failure == 'network') {
          expect(primary.last?.disposed, isTrue);
          expect(app.connection.selected.value?.id, second.id);
          expect(app.connection.state.value, DeviceConnectionState.connected);
          expect(alternative.last?.powerControl.shutdowns, 0);
          expect(
            app.savedDevices.logicalDevice(tv.id)?.preferredProfile.id,
            tv.id,
          );
        } else {
          expect(alternative.last, isNull);
          expect(app.connection.errorCode.value, 'tls');
        }
        await app.dispose();
      },
    );
  }
}
