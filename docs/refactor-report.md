# Context and readability refactor

This supersedes the old MVP report for source organization, navigation dependency,
and validation results. The LG-first scope and hardware caveats remain unchanged.

## Reference review

Kap Games' app bootstrap/dependencies, route wiring, project-structure guide,
login page/viewmodel, domain managers and domain models were inspected. The useful
patterns were carried over: explicit composition, constructor injection, routed
pages under presentation/views, feature viewmodels/viewports, domain services,
data adapters, and small context-owned widgets. Kap Games was not changed.

## Changes

- Replaced the broad app/controllers.dart, core/storage.dart, core/diagnostics.dart,
  flat features files, and package device/capability/provider bundles with their
  owning contexts. Every class, widget State, enum, and test double has its own
  file; package entrypoints remain public API barrels.
- Split remote screens into a thin page, viewmodel, viewport, header, navigation
  pad/buttons, volume card, app/input actions, offline actions, and pairing progress.
  Device discovery, settings, and the connection editor have the same separation.
- Moved manual LG profile validation out of bootstrap and widget callbacks into
  a dedicated data factory. Moved persisted profile conversion into its mapper.
  The domain profile service depends on a repository contract implemented by data.
- Separated UI session ownership, volume observation, and command progress/errors.
  State/lifecycle code uses cancellation and stale-session guards before continuing.
- LG capability controllers use a narrow command channel, pointer connection, or
  connection options; they no longer receive the device owner and reach into its
  private fields. Capability probing/evidence have their own registry/resolver.
- SSAP incoming envelopes, pending request completion/deadlines, subscription
  lifecycle, error interpretation and session dispatch are separate responsibilities.
  SSDP discovery delegates socket/timer/packet ownership to a search session.
- Converted nested branches into guards and named operations. Production code
  passes the two-level executable control-flow check and contains no else branches.
  Widget composition is shallow and divided into named visual contexts.
- Added the source structure conventions to AGENTS.md, a context-based navigation
  guide, and MIND-MAP.md so future changes follow the same rules.

DDD and object-calisthenics principles are applied to concrete responsibility and
dependency boundaries. The refactor does not introduce empty integration packages,
a container framework, new business features, or wrappers for every primitive.

## route_definer

The local updated manifest is 4.0.0, with Flutter and meta as runtime dependencies.
The pushed remote HEAD matched local commit
`7546848c78ab81a208655ad7083f608942309b63`. The app pins that Git revision, so
navigation works without an absolute local library path. At verification time
pub.dev still reported the older 3.2.0 manifest with web. No package implementation
was copied into this project.

AppRoutes owns the route table and navigation decisions; MaterialApp.router
consumes its router. The route object is scoped to the app and disposed with it.
The dependency snapshot contains 91 entries and checks the precise Git revision.
route_definer introduces no direct web requirement. Existing authorized storage/test
transitives may still include web, as recorded in dependencies.md.

The workspace root now explicitly lists the three repository packages as development
dependencies for the pre-existing smoke tools. No independently maintained package
was added for the refactor's checks.

## Readability enforcement

`dart run tool/check_structure.dart` uses only Dart SDK libraries. It checks one
type per file (including fixtures), guard-clause style, shallow control-flow blocks,
and pure-Dart/domain dependency directions. The lexical scanner masks comments
and strings; it is a lightweight structural guard, not a semantic proof of design
quality. Its four regression tests cover actual acceptance/rejection behavior.
Dart analysis also enforces control-flow braces. Both checks are in CI.

Automatic approval review rejected declaring analyzer as another direct development
dependency because it was not explicitly authorized. That declaration was removed;
the persisted tool does not import or require analyzer. Existing Flutter/Dart
analysis remains part of normal verification.

## Validation

- Formatting: all 155 Dart files formatted; final check reports zero changes.
- Static analysis: passed, no issues.
- Structure check: passed.
- Dependency audit: passed, 91 reviewed entries, pinned route_definer 4.0.0,
  no Riverpod.
- Package/protocol tests: 27 passed.
- Readability-rule tests: 4 passed.
- Flutter/application tests: 8 passed.
- Total automated tests: **39 passed**.
- Original SDK-only smoke runner: 11 checks passed, exit 0.
- Android ARM64 debug build: passed; updated APK copied to
  artifacts/universal-remote-android-arm64-debug.apk.
- iOS simulator debug build: passed.
- macOS debug build: passed.
- GitHub CI: configuration updated; not executed remotely in this local workspace.

Existing behavior assertions were retained. The pairing widget test now allows
route resolution/animation to complete instead of assuming an immediate IndexedStack
switch. Fake providers and credentials remain test-only.

## Review entrypoints

- [Source map](contexts/flutter/project-structure.md)
- [Readability conventions](contexts/architecture/readability-rules.md)
- App wiring: apps/universal_remote_app/lib/app/app_bootstrap.dart
- Navigation: apps/universal_remote_app/lib/routes/app_routes.dart
- Remote composition: presentation/views/remote/viewports/remote_viewport.dart
- Remote actions: presentation/views/remote/viewmodels/remote_viewmodel.dart
- Domain lifecycle: domains/connection/services/connection_controller.dart
- LG orchestration: remote_lg_webos/lib/src/devices/services/lg_device_controller.dart
- SSAP coordination: remote_lg_webos/lib/src/protocol/services/ssap_client.dart

## Limits

Physical TV/mobile behavior remains unverified, including firmware-specific
permissions, actual Keychain/Keystore persistence, TLS provisioning and network
wake. iOS physical multicast discovery still needs Apple's entitlement/provisioning
approval. This refactor does not change those release gates or claim hardware
certification. No native-app automation or visual inspection was required for the
source-structure work; UI behavior was checked with the existing widget suite.
