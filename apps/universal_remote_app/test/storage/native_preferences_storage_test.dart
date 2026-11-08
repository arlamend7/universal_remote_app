import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/data/storage/adapters/native_preferences_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test.native_preferences');
  final values = <String, String>{};
  final calls = <MethodCall>[];
  setUp(() {
    values.clear();
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          final arguments = Map<String, Object?>.from(call.arguments as Map);
          final key = arguments['key'] as String;
          switch (call.method) {
            case 'read':
              return values[key];
            case 'write':
              values[key] = arguments['value'] as String;
              return null;
            case 'delete':
              values.remove(key);
              return null;
          }
          throw StateError('Unexpected native method.');
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test(
    'ordinary preferences use native read/write/delete operations',
    () async {
      final storage = NativePreferencesStorage(channel: channel);
      await storage.write('settings.theme', 'dark');
      expect(await storage.read('settings.theme'), 'dark');
      await storage.delete('settings.theme');
      expect(await storage.read('settings.theme'), isNull);
      expect(calls.map((call) => call.method), [
        'write',
        'read',
        'delete',
        'read',
      ]);
    },
  );
  test('credential keys cannot reach ordinary native preferences', () {
    final storage = NativePreferencesStorage(channel: channel);
    expect(() => storage.write('client-key.tv', 'secret'), throwsArgumentError);
    expect(() => storage.read('client-key.tv'), throwsArgumentError);
    expect(() => storage.delete('client-key.tv'), throwsArgumentError);
    expect(calls, isEmpty);
  });
}
