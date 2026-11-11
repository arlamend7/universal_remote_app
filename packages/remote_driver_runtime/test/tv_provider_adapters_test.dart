import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/tv_provider_adapters.dart';
import 'package:test/test.dart';

import 'memory_driver_credentials.dart';

void main() {
  test('shared registration preserves saved provider IDs and Roku opt-in', () {
    final credentials = MemoryDriverCredentials();
    final standard = TvProviderAdapters.create(
      credentials,
      (_) => null,
      enableRoku: false,
    );
    final development = TvProviderAdapters.create(
      credentials,
      (_) => null,
      enableRoku: true,
    );

    expect(
      standard.definitions.map((definition) => definition.identifier.id),
      unorderedEquals(['lg.webos', 'android.tv', 'samsung.tizen']),
    );
    expect(development.isRegistered(ProviderIdentity.roku.storageId), isTrue);
  });
}
