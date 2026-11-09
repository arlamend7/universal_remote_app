import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/presentation/views/devices/viewmodels/device_editor_viewmodel.dart';

void main() {
  test(
    'an automatic match selects the provider without a platform choice',
    () async {
      final response = Completer<List<String>>();
      final model = _model((host, _) {
        expect(host, '192.168.1.42');
        return response.future;
      });
      addTearDown(model.dispose);
      final submission = model.submit();
      expect(model.checking.value, isTrue);
      response.complete(['samsung']);
      expect((await submission)?.providerId, 'samsung');
      expect(model.checking.value, isFalse);
    },
  );

  test('ambiguous results leave manual selection available', () async {
    final model = _model((_, _) async => ['lg', 'samsung']);
    addTearDown(model.dispose);
    expect(await model.submit(), isNull);
    expect(model.error.value, contains('More than one platform'));
    model.provider.value = 'lg';
    expect((await model.submit())?.providerId, 'lg');
  });

  test('closing the form cancels detection and ignores a late match', () async {
    final response = Completer<List<String>>();
    late DiscoveryCancellation token;
    final model = _model((_, cancellation) {
      token = cancellation;
      return response.future;
    });
    final submission = model.submit();
    model.dispose();
    expect(token.isCancelled, isTrue);
    response.complete(['samsung']);
    expect(await submission, isNull);
  });
}

DeviceEditorViewModel _model(
  Future<List<String>> Function(String, DiscoveryCancellation) identify,
) => DeviceEditorViewModel(
  factory: _factory('fallback'),
  identifyAddress: identify,
  setups: {
    'lg': (label: 'LG', showsAdvancedSetup: true, factory: _factory('lg')),
    'samsung': (
      label: 'Samsung',
      showsAdvancedSetup: true,
      factory: _factory('samsung'),
    ),
  },
)..address.text = '192.168.1.42';

ManualDeviceFactory _factory(String provider) =>
    ({
      required address,
      required name,
      required legacy,
      required allowInsecurePointer,
      certificate,
      mac,
      broadcast,
      existing,
    }) => RemoteDevice(id: provider, name: name, providerId: provider);
