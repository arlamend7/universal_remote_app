# Driver validation and release gates

## Dependency boundaries

The app assembles the existing provider registry and supplies platform signature verification, storage, and protected credentials. The manager owns version selection, distribution and activation. The runtime validates bounded workflows and uses the same network transports as the compiled engines.

```mermaid
flowchart TD
  App[universal_remote_app] --> Manager[remote_driver_manager]
  App --> UI[remote_ui]
  App --> Runtime[remote_driver_runtime with compiled adapters]
  Manager --> Runtime
  Manager --> Core[remote_core]
  Manager --> Network[remote_network]
  Runtime --> Core
  Runtime --> Network
  Network --> Core
  UI --> Core
  Authoring[Driver authoring tools] --> Runtime
  Authoring --> Pages[Signed GitHub Pages artifacts]
  Manager --> Pages
```

## Connection flow

```mermaid
flowchart LR
  Device[Nearby or manual IP] --> Evidence[Provider and device evidence]
  Evidence --> Prepare[Resolve and prepare local release]
  Catalog[Verified catalog and immutable packages] --> Prepare
  Prepare --> Connect[Authenticate with the selected protocol]
  Connect --> Identify[Read fresh TV software evidence]
  Identify --> Profile[Resolve the compatibility profile]
  Profile --> Verify[Apply restrictions and check capabilities]
  Verify --> Remote[Show supported controls]
  Profile -. Incompatible declarative release .-> Replace[Authenticate one same-family replacement]
  Replace --> Verify
```

## Automated checks

Run these commands from the repository root with the pinned Flutter SDK.

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed packages apps/universal_remote_app/lib apps/universal_remote_app/test test tool
dart analyze --fatal-infos
dart run tool/check_structure.dart
dart run tool/audit_dependencies.dart
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s drivers/tests
dart test test packages/remote_core/test packages/remote_network/test packages/remote_driver_runtime/test packages/remote_driver_manager/test
cd apps/universal_remote_app
flutter test --no-pub
flutter build apk --release --no-pub
flutter build ios --simulator --debug --no-pub
flutter build macos --debug --no-pub
```

The signed distribution fixture covers catalog and package verification, revision rollback, transfer deduplication, Nearby discovery, choosing a compatible driver, first installation and offline manual reconnect. Existing provider fixtures cover preserved transport behavior. Publication tests build the full release index with an ephemeral key and check that each artifact is available at the path signed in the catalog.

### Follow-up results

At implementation commit `b19de6d`, all 131 Dart tests, 133 Flutter tests and five publication tests passed. Formatting, static analysis, project structure, dependency audit and validation of the four 1.1.0 source bundles passed. The Android release APK, iOS simulator debug and macOS debug builds succeeded. These are build and fixture results.

The handoff fixture covers an accepted replacement, a rejected authorization, and a replacement that offers no authentication. The original socket stays open during replacement authorization. A failed handoff preserves the stored credential.

## Platform and compatibility limits

- The generic controller supports typed command arguments, catalog and status results, authenticated sessions and subscriptions where a bundle declares usable operations. It can make one authenticated same-family handoff when fresh software evidence invalidates the initial release.
- The runtime owns the compiled SSAP, Remote v2, Samsung channel and ECP protocol primitives. Provider adapters still supply discovery identity, typed controllers, protocol policy and capability checks. The candidate 1.1.0 bundles remain outside the publication index. The [provider inventory](current-provider-inventory.md) and [TV API matrix](parity/tv-api.md) identify remaining provider-specific behavior.
- Device OS, model and firmware constraints require matching evidence. Unknown evidence can match a generic profile. Firmware range comparison requires a strategy for the particular platform.
- Native signature verification is configured on Android, iOS and macOS. Apple Bonjour services must also be declared in the app bundle. A newly introduced Bonjour service type can require an app release on Apple platforms. [Apple local network privacy](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy)
- Driver releases contain declarative data. A native operation or executable protocol engine ships through the app release process. App Store review and Google Play policy remain separate release gates. [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) · [Google Play Device and Network Abuse policy](https://support.google.com/googleplay/android-developer/answer/16559646)

## Release and hardware verification

Production deployment requires a configured Pages source, protected environment, production signing key, and a release build with the corresponding trusted public key. Follow [publishing](publishing.md) and confirm that the deployment URL serves the exact catalog and package paths. The feature branch validates signing with ephemeral keys.

Physical-device verification remains pending. Exercise at least one physical TV per enabled provider before claiming hardware compatibility. Roku testing uses an opt-in development build. The provider adapters now live inside the shared runtime.

| Target | Verify on hardware |
| --- | --- |
| LG webOS | Existing saved profile, registration and TLS, navigation and pointer, volume and mute, apps, inputs, wake. |
| Android TV | Pairing code, TLS pin and reconnect, navigation, media, volume and wake on a supported device. |
| Samsung Tizen | Certificate and token persistence, navigation, channels, volume, app launch and wake. |
| Roku development build | Local ECP discovery and serial match, permission and capability gates, volume and power on supported hardware. |
| Cross-provider | First install, disconnected catalog, reconnect without Internet, persisted dashboards and credentials, update during an active session, and rollback. |
