import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:remote_core/remote_core.dart';
import 'package:remote_android_tv/remote_android_tv.dart';
import 'package:remote_lg_webos/remote_lg_webos.dart';
import 'package:remote_roku/remote_roku.dart';
import 'package:remote_samsung_tizen/remote_samsung_tizen.dart';

/// Compiled protocol adapters shared by built-in and managed providers.
abstract final class BuiltInProviders {
  static ProviderRegistry create(
    CredentialStore credentials,
    DriverBindingsLookup bindings,
  ) {
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
    if (!kReleaseMode && const bool.fromEnvironment('ENABLE_ROKU_ECP')) {
      providers.registerDefinition(RokuProvider(bindings: bindings).definition);
    }
    return providers;
  }
}
