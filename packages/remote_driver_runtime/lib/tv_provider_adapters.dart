import 'package:remote_core/remote_core.dart';

import 'src/adapters/android_tv/android_tv_provider.dart';
import 'src/adapters/lg_webos/providers/lg_web_os_provider.dart';
import 'src/adapters/roku/roku_provider.dart';
import 'src/adapters/samsung_tizen/samsung_provider.dart';

export 'src/adapters/lg_webos/discovery/lg_identifier.dart';
export 'src/adapters/lg_webos/providers/lg_web_os_provider.dart';

/// Compiled protocol adapters shared by built-in and managed providers.
abstract final class TvProviderAdapters {
  static ProviderRegistry create(
    CredentialStore credentials,
    DriverBindingsLookup bindings, {
    required bool enableRoku,
  }) {
    final providers = ProviderRegistry()
      ..registerDefinition(
        LgWebOsProvider(
          credentials: credentials,
          bindings: bindings,
        ).definition,
      )
      ..registerDefinition(
        AndroidTvProvider(
          credentials: credentials,
          bindings: bindings,
        ).definition,
      )
      ..registerDefinition(
        SamsungProvider(
          credentials: credentials,
          bindings: bindings,
        ).definition,
      );
    if (enableRoku) {
      providers.registerDefinition(RokuProvider(bindings: bindings).definition);
    }
    return providers;
  }
}
