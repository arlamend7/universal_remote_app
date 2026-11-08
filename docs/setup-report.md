> Historical foundation report. The current scope and dependency decisions are in implementation-report.md and dependencies.md.

# Initial setup report — November 3, 2026

## Completed scope

Created a Pub workspace with four unpublished repository-owned packages:

- `remote_core` 0.1.0: immutable device/capability models, driver lifecycle
  contract, and platform-independent `CredentialStore` interface.
- `remote_network` 0.1.0: injectable `TextTransport` and `dart:io` WebSocket
  transport with bounded handshake, text-frame checks, close handling, and
  send-after-close rejection.
- `remote_lg_webos` 0.1.0: numeric TV endpoint validation and SSAP request
  envelope serialization. No registration or authenticated session yet.
- `universal_remote_app` 0.1.0+1: Flutter connection-check screen using
  constructor injection, `ChangeNotifier`, and `ListenableBuilder`, with
  Android, iOS, and macOS starter projects.

Installed tooling verified: Flutter 3.47.5 stable, Dart 3.13.4. Workspace SDK
constraints deliberately match the installed Dart version; minimum-version
compatibility has not been tested. No third-party lint/test packages added.

## Ownership policy

The supplied policy is preserved in [dependency-policy.md](dependency-policy.md).
The user explicitly approved **Flutter's required dependencies only** after
being shown the five hosted dependencies below. This exception does not extend
to additional independently published packages or to `web`.

There are no unapproved resolved Dart/Flutter dependencies. The five hosted
packages are exceptions to the original DEVCOM-only rule, recorded explicitly.
The guard in `tool/audit_dependencies.dart` fails on new package names/sources,
new direct hosted dependencies, or package-server URLs other than pub.dev.
It is an initial baseline check, not automatic publisher verification for future
packages. Review publishers, public APIs, SDK compatibility, and full dependency
graphs again before expanding it.

## Complete direct dependency inventory

| Workspace package | Direct dependencies | Development dependencies |
| --- | --- | --- |
| `universal_remote_workspace` | None | None |
| `remote_core` | None | None |
| `remote_network` | None | None |
| `remote_lg_webos` | `remote_core`, `remote_network` | None |
| `universal_remote_app` | `flutter`, `remote_core`, `remote_network`, `remote_lg_webos` | None |

All `remote_*` packages resolve to source in this repository. The workspace
root is private coordination metadata, not a fifth reusable package.

## Complete external and SDK dependency inventory

These are the seven entries in the root `pubspec.lock`, verified with
`flutter pub deps --json`. There are no other resolved transitive packages.

| Dependency | Version | Source | Used by |
| --- | --- | --- | --- |
| `flutter` | 0.0.0 (SDK placeholder) | Installed official Flutter SDK 3.47.5 | App |
| `sky_engine` | 0.0.0 (SDK placeholder) | Installed Flutter SDK | Flutter |
| `characters` | 1.4.1 | Hosted pub.dev; Dart team, dart-lang/core | Flutter |
| `collection` | 1.19.1 | Hosted pub.dev; Dart team, dart-lang/core | Flutter and material_color_utilities |
| `material_color_utilities` | 0.13.0 | Hosted pub.dev; Material Foundation upstream | Flutter |
| `meta` | 1.19.0 | Hosted pub.dev; Dart SDK upstream | Flutter |
| `vector_math` | 2.4.3 | Hosted pub.dev; Flutter core-packages upstream | Flutter |

The hosted packages are independently distributed packages, not SDK-source
entries. Their upstream development dependencies are not propagated into this
workspace. In particular, no `test`, `flutter_test`, `flutter_lints`, `lints`,
or mocking package is resolved here. Existing cache contents are not project
dependencies. The root lockfile contains the exact package archive hashes.

## DEVCOM package review

The [current verified publisher list](https://pub.dev/publishers/devcom.net.br/packages)
shows `route_definer` 3.2.0, `flutter_client_factory` 1.0.3, `envx` 2.0.0,
`flutter_client_factory_widgets` 1.0.3, and `universal_ble_server` 0.2.0.
Published sources already present in the local pub cache were inspected where
relevant; this project does not add path dependencies to that cache.

| Package | Findings and decision |
| --- | --- |
| `route_definer` 3.2.0 | Public `createMaterialRouter`, `RouteDefiner.simple`, and `RouteDefinerRouter` APIs fit later navigation. Dart >=3.6, Flutter >=3.27 fit the installed SDK. Runtime dependencies: Flutter, `meta`, and `web`. `web` is outside the approved Flutter baseline. Defer routing; the starter has one screen. Compliant solution: remove the dependency upstream when feasible before reuse. No competing router added. |
| `flutter_client_factory` 1.0.3 | Public `DefaultHttpClientFactory`, `registerClient`, `create`, and HTTP response/body APIs inspected. Dart >=3.4 fits. No runtime dependencies. Reserve for future HTTP; the starter only uses WebSockets. Upstream `test` is a development dependency and would not propagate to consumers. |
| `envx` 2.0.0 | Public `Environment.register`, `EnvironmentInstance`, and `EnvxBuilder` exports inspected. Dart >=3.0 fits. No runtime dependencies. No layered environment configuration is needed yet, so it is not added. Upstream `lints`/`test` are development-only. |
| `flutter_client_factory_widgets` 1.0.3 | Listed as optional resource-state adapters. Not added: no HTTP resources exist. Its source/API/dependency review is deferred until a real use case arises; no compatibility assumption is made. |
| `universal_ble_server` 0.2.0 | Cached manifest inspected: Dart ^3.8.1, Flutter >=3.32 fit. Depends on Flutter, flutter_web_plugins, and `plugin_platform_interface`. The latter is outside policy and would need an upstream SDK-only solution or explicit exception before use. No BLE needed or added. Its public BLE API is not relied on in this milestone. |

No features currently rely on a DEVCOM hosted package: none provides a required,
compliant feature for this setup milestone. No duplicate HTTP client or
configuration system was created. The `HttpClient` inside WebSocket connection
setup is solely the SDK's handshake resource, not an application HTTP layer.

## Native setup and security

Generated standard Kotlin Android and Swift Apple Flutter runners. Added
Android Internet permission and cleartext allowance for the port-3000 local
WebSocket probe, Apple local-network usage descriptions, and macOS outbound
network entitlements in debug/release configurations. Removed the automatically
selected personal iOS signing team from the project; select your team in Xcode
when building for a physical device.

No custom platform channels, Keychain integration, Keystore integration,
preferences, BLE, or infrared modules have been created. `CredentialStore` is
an interface only. There is no plaintext pairing-key persistence, credential
logging, custom cryptography, or TLS certificate bypass. The UI displays generic
network errors and never raw protocol payloads.

The probe uses unencrypted local `ws` and sends no credentials. Before pairing,
resolve the device's TLS/trust strategy and revisit broad Android cleartext
access. The endpoint utility's optional `wss` support retains normal certificate
validation and may reject TVs with untrusted certificates.

## Validation and build results

- Dependency resolution: `flutter pub get --offline` succeeded.
- Analyzer: `dart analyze` succeeded with no issues.
- SDK-only smoke suite: 11 explicit checks passed with exit code 0. Covers
  immutable capability input, unsupported capability lookup, invalid device ID,
  invalid/loopback TV addresses, standard/secure endpoint selection, SSAP request
  encoding/validation, local WebSocket round trip, and send-after-close handling.
- Ownership guard: passed; all 12 graph entries are the workspace root, four
  local packages, two SDK packages, and five approved hosted dependencies.
- macOS debug build: succeeded. Xcode reports its standard generated Run Script
  phase warning about running every build; this does not fail compilation.
- Android and iOS builds: not executed. Widget automation, release builds,
  CI execution, and live-device testing: not executed.

The suite does not yet cover pairing, correlation, secure storage, discovery,
or remote commands because those features have not been implemented. It uses a
real local in-process WebSocket fake server without third-party test packages.

## Hardware limits and next milestones

No physical LG TV was contacted. A successful probe only proves a WebSocket
handshake; it does not verify TV identity, SSAP permissions, pairing, or commands.
OS local-network permission prompts, TLS-only TVs, Apple signing, Android network
policies, and device-specific webOS behavior still need hardware validation.

Continue with SSAP registration and pairing lifecycle, bounded request/response
correlation and cancellation, native Keychain/Keystore storage, volume and
navigation, then SSDP discovery. Keep BLE outside the LG-first scope.

Potential future DEVCOM extractions: native secure storage, network service
discovery, and reusable remote capability/protocol modules. These remain private
workspace responsibilities; no publication or package-name availability claims
are made. Verify names and API stability before planning publication.
