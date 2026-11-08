> Historical MVP report. The current source layout, route_definer decision and validation results are in refactor-report.md.

# LG webOS MVP implementation report — November 3, 2026

## Result and scope

The initial WebSocket probe has been replaced by a capability-based LG webOS
application and reusable protocol packages. This is a locally tested MVP, not a
hardware-certified production release. No physical TV or mobile device was used.

The latest user instruction explicitly replaces Riverpod with the injection
approach used in Kap Games. The implementation uses `AppBootstrap.initialize`,
a concrete `AppDependencies` lifetime container, constructor-injected services
and screens, and SDK `ValueNotifier`/`ListenableBuilder` for state. Riverpod,
flutter_riverpod, state_notifier, and their exclusive dependencies were removed
from the resolved graph. Secure storage and testing dependencies remain under
the user's explicit authorization.

## Architecture and packages

| Package | Implemented responsibility |
| --- | --- |
| remote_core 0.1.0 | Immutable metadata/categories, evidence provenance, typed capability contracts, safe errors, provider selection, concurrent discovery, deduplication, timeout/cancellation and lifecycle contracts |
| remote_network 0.1.0 | SDK text WebSocket, endpoint-scoped TLS trust, bounded handshake/frame handling, socket state, IPv4 SSDP parsing/search/cancellation, WOL framing/transmission |
| remote_lg_webos 0.1.0 | LG provider/manual profiles, SSAP prompt registration and client-key reuse, request IDs/correlation/concurrency, subscriptions and cleanup, separate pointer socket, capabilities and bounded reconnection |
| universal_remote_app 0.1.0+1 | Responsive Material 3 screens, discovery/manual entry, approval progress/cancellation/retry, saved TVs/edit/re-pair/forget, typed remote controls, themes/diagnostics, native storage adapter and app lifecycle coordination |

No empty future-manufacturer packages were created. Core and protocol packages
have no Flutter imports. No backend, database, cloud account, analytics, package
publication, release deployment, or external messaging was added.

## Features implemented and limits

- Discovery searches for LG's advertised second-screen service, validates UUID
  identities, normalizes headers, isolates malformed traffic, and deduplicates.
  Friendly name and model use available advertisement headers; otherwise they
  remain generic/unknown. UPnP XML description fetching, interface selection, and
  IPv6 discovery are not implemented. Manual numeric-IP profiles work independently
  of discovery and have random saved identities instead of permanent IP identities.
- TLS port 3001 is the default. Exact certificate provisioning is per device;
  an empty trust store ensures the explicit pin is actually checked. There is no
  global trust-all override or silent fallback. Legacy port 3000 and legacy pointer
  sockets require explicit choices. Certificate rotation requires updating the pin.
- Pairing uses an unsigned, versioned prompt manifest with scoped permissions.
  It distinguishes prompt acknowledgement from authorization, times out, stores
  the returned key securely, reuses it, handles revoked/rejected keys, and supports
  cancellation/re-pair/forget. Manifest injection permits verified firmware profiles;
  no single manifest is claimed to work on every firmware.
- SSAP supports concurrent requests, unique IDs, JSON framing, typed safe errors,
  per-request deadlines, subscription setup deadlines, unsubscribe, and cleanup
  on malformed messages, disconnect and disposal. Pending futures are failed.
- Volume up/down/set, mute/unmute, state reads and optional updates are implemented.
  Navigation uses a separate socket and the required blank-line separators; OK is
  a pointer click. Power-off asks for confirmation. Power is driver-known rather
  than falsely claimed verified by a destructive probe.
- Apps/inputs are listed from the TV and controlled using returned IDs. The package
  can query foreground application state; the UI does not display it continuously.
  No unverified current-input operation is invented.
- WOL is available only with a valid explicitly configured MAC address. A successful
  UDP send does not establish that the television woke.
- Unexpected connection loss triggers bounded retries with backoff. Backgrounding,
  cancellation and disposal release session resources. Foreground resumption may
  reconnect an active session; background persistence is not promised.
- Controls depend on typed capabilities; unsupported/denied controls are disabled.
  Settings exposes capability evidence. An operation may still fail after a probe
  due to firmware/permissions/network state changes.

## Dependency inventory and policy

The original mandatory policy and supplied specification are preserved verbatim
in dependency-policy.md and project-specification.md. Subsequent user decisions
are recorded in AGENTS.md and dependencies.md, and take precedence.

There are **90 resolved graph entries**, including the workspace root, four local
packages, SDK packages, and the secure-storage/testing dependency trees. Every
package, version, distribution source, and resolved dependency edge is listed in
[dependencies.md](dependencies.md) and [dependency-graph.json](dependency-graph.json).
The root pubspec.lock pins archive hashes. All 90 resolved package manifests were
inspected. SDK compatibility was established through actual resolution/analysis
and the native builds below. Upstream development dependencies do not propagate.

There are no unapproved direct dependencies in the current project. The externally
maintained secure-storage/test trees are exceptions to the original DEVCOM-only
policy under the user's revised authorization. No current feature uses a DEVCOM
hosted package because this milestone needs SDK WebSocket/UDP and the explicitly
requested storage/test stack. No competing HTTP infrastructure was introduced.

`route_definer` remains deferred: automatic approval review rejected adding it
because its `web` dependency was outside that action's explicit authorization.
The later appearance of `web` in authorized secure-storage/test transitives is
recorded and does not itself add route_definer. Flutter's standard navigation
widgets are used without a competing routing package.

The current audit compares the complete graph to its reviewed snapshot and
explicitly rejects Riverpod. Future changes require a fresh source/API/constraint
and transitive-dependency review before updating the snapshot.

## Native integrations

- `SecureCredentialStore` delegates to flutter_secure_storage 11.2.0, with Apple
  Keychain and Android Keystore-backed encrypted storage. There is no custom
  cryptography, plaintext fallback, or pairing-key logging. Profiles/settings use
  separate protected records; client keys are not stored in profile JSON.
- Android: Internet/Wi-Fi/multicast permissions, explicit legacy cleartext support,
  backup disabled, minimum API 24, and an application-owned multicast-lock method
  channel with release on completion/cancellation/activity stop.
- iOS: local-network usage description, local-network ATS allowance, Keychain and
  multicast entitlements, minimum iOS 15. Actual multicast provisioning still needs
  Apple approval and signing setup; source configuration cannot grant it.
- macOS: outbound network sandbox entitlements and native Keychain use without
  shared-access/data-protection provisioning for local development.

No infrared, BLE, network-monitoring plugin, or unnecessary future native module
was created.

## Validation results

| Check | Result |
| --- | --- |
| Formatting | 30 Dart files checked; zero outstanding changes |
| Static analysis | Passed, no issues found |
| remote_core | 6 tests passed |
| remote_network | 8 tests passed, including local TLS certificate acceptance/rejection |
| remote_lg_webos | 13 tests passed, including a real local WebSocket fake-server integration |
| Flutter/application | 8 tests passed: protected storage boundaries, injected bootstrap/persistence/disposal, enabled and disabled capability controls, discovery/selection, pairing/cancellation, errors, manual validation |
| Total automated tests | **35 passed** |
| Original SDK-only smoke suite | 11 checks passed; exit 0 |
| Dependency audit | Passed: 90 reviewed entries, no Riverpod |
| Android ARM64 debug APK | Built successfully with final application source |
| iOS simulator debug | Built successfully with final source and entitlements; no physical signing claim |
| macOS debug | Built successfully after removing generated build artifacts to free disk space |
| GitHub Actions | Workflow configured; not executed remotely because no Git repository/remote is configured |

Initial Android/macOS build attempts failed because the disk filled. Only generated
build outputs inside this project were removed; subsequent builds succeeded.
The Android APK was preserved at
`artifacts/universal-remote-android-arm64-debug.apk`; its large intermediate build
folder was removed to permit the final iOS build. The desktop UI inspection tool
was unresponsive, so native visual/interactive inspection is not claimed. Widget
behavior was verified by the automated Flutter tests above.

No physical television was needed for automated tests. TLS certificates and fake
credentials are test-only, temporary/in-memory fixtures. No production mock TVs
or placeholder control methods were introduced.

## Exact run commands

From the project root:

```sh
export PATH="/Users/karoline/Code/Dependencs/flutter/bin:$PATH"
flutter pub get --enforce-lockfile
cd apps/universal_remote_app
flutter devices
flutter run -d <device-id>
```

Use an actual ID printed by flutter devices; select your iOS signing team in Xcode
for physical builds. The README contains all format/test/audit/build commands.
The generated APK is a debug ARM64 build, not a signed release or universal APK.

## Remaining hardware and release work

Use hardware-checklist.md to validate TV model/firmware permissions, prompt
behavior, native persistence/revocation, secure/legacy pointer combinations,
volume/audio-output cases, apps/inputs, power/wake, mobile lifecycle and Wi-Fi
transitions. iOS multicast entitlement approval and physical provisioning remain
external requirements. Protected storage is tested via an injected fake and native
compilation; its real-device persistence has not been claimed verified.

Next priorities: real LG testing; run CI in an actual repository; improve SSDP
interface selection and bounded metadata enrichment; extend device-size/accessibility
coverage; test sustained reconnection/cancellation races and model-specific
firmware profiles. Release signing, publication and distribution remain future work.

Potential reusable DEVCOM extractions are discovery, secure-storage adapters,
capability contracts, and protocol integrations once their APIs stabilize.
No publication was planned and no package-name availability is claimed.
