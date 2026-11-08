# Universal Remote

An LG-first, local-first universal remote built with Flutter and reusable Dart
packages. Phase 1 supports compatible LG webOS televisions. Other manufacturers
and device categories are architectural extension points, not shipped integrations.

## Implemented

- IPv4 SSDP discovery with UUID deduplication and manual numeric-IP profiles.
- Secure WebSocket by default, per-device certificate provisioning, explicit
  legacy transport, prompt pairing, protected client-key storage and reuse.
- Typed volume/mute, navigation/OK/Back/Home, power-off, applications, inputs,
  optional current-app/live-channel feedback and live-TV channel adjustment.
- Optional volume subscriptions and Wake-on-LAN with automatic address learning.
- Minimal Remote/Devices navigation, compact TV rows, contextual sheets and
  per-device grid controllers, reusable groups and a searchable 77-choice catalog.
- Saved TVs, local names, connection details, re-pair/forget, light/dark/system
  themes, controlled diagnostics, and foreground/background lifecycle handling.
- Request correlation, timeouts, subscription cleanup, bounded reconnection,
  capability checks and unavailable-control feedback.

**No physical LG TV has been verified yet.** Automated tests use in-process
servers and injected providers. Discovery names/models use advertised metadata;
UPnP XML descriptions and IPv6/interface selection remain future improvements.

## Requirements

Flutter 3.47.5 stable / bundled Dart 3.13.4, Android SDK and JDK 17 for Android,
and macOS/Xcode for iOS. Android minimum API 24; iOS minimum 15. macOS is an
additional development target; Windows/Linux runners have not been generated.
OpenSSL is used only to generate ephemeral certificates in the TLS test suite.

On the setup machine, the SDK lives at
`/Users/karoline/Code/Dependencs/flutter/bin`. Add this directory to PATH.

## Setup and run

From the workspace root:

```sh
export PATH="/Users/karoline/Code/Dependencs/flutter/bin:$PATH"
flutter pub get --enforce-lockfile
cd apps/universal_remote_app
flutter devices
flutter run -d <device-id>
```

Choose an actual device ID from `flutter devices`. For example, use an Android
emulator or an iOS simulator identifier. Physical iOS builds require selecting
your signing team and an appropriate provisioning profile in Xcode.

This is a Pub workspace: commit the root pubspec.lock; do not resolve packages
as unrelated projects. No cloud backend, database, user accounts, analytics,
release publication, or internet-facing control server is required.

## Customize your remote

Open the TV’s **⋯ → Customize remote** for its own editing page. Switch between
**View** (a clean preview) and **Edit** (move, resize and remove handles).
Drag with a mouse, or hold and drag on touch. Tap a control to change its style,
name or size, or pull its corner to resize it. Nearby controls make room automatically.
**Done** saves only to that TV; **Cancel** discards the draft.
View mode uses clearly labeled sample channel, app, volume and connection data;
it never changes the live TV state. Both the live remote and View preview fit the
available screen without page scrolling. The header has no reserved empty status
row; tap its status indicator for connection details.
The live remote and editor use the same grid. Devices without a saved grid
start with the starter controls. Device
addresses, pairing and capabilities live under **⋯ → View details → Device settings**.
Global **App preferences** are available from the Devices gear. Current app/channel information is shown
only when reported by the TV; use Re-pair if an older authorization lacks the
required feedback permissions.

See [the grid guide](docs/contexts/flutter/modular-grid-controller.md)
and [the original layout guide](docs/contexts/flutter/minimal-controller-layout.md)
and actual Flutter previews under artifacts/design/implemented-v1.

## Connect a TV

1. Turn on the TV and connect it and your phone to the same trusted LAN.
2. Grant local-network access. Open **Find Nearby Devices** and add a new TV from
   its discovery modal. Registered TVs appear under **Already added**, with an
   explicit address-update action. Use **Connect by IP** when multicast is blocked.
   An on-TV network setting provides its IP address.
3. The default is TLS on port 3001. If its certificate is rejected, choose
   **Review TV certificate and pair**. Confirm the IP on your TV and review the
   certificate before choosing **Trust and pair** on your trusted network.
   You can also provision an independently verified certificate in Connection
   details. Unknown or changed certificates require explicit approval. See docs/security.md.
4. Only if appropriate for your trusted network, explicitly choose legacy
   unencrypted port 3000 or allow an unencrypted pointer socket. No silent
   fallback occurs.
5. Approve the prompt displayed by the TV. Authorization is saved in native
   protected storage and reused later. Use Re-pair after revocation, or Forget
   to delete the local key/profile.
6. Controls enable when their capability checks succeed. Power-off is
   driver-known, rather than destructively probed. Wake requires a valid TV MAC
   and TV/network support; sending a packet does not guarantee wake.

For wake setup, turn on the TV manually and connect once. The app attempts to
learn the active interface's MAC and subnet broadcast after pairing. Check
**View details → Network wake**. If detection is unavailable, enter the MAC and
optional broadcast under **Connection settings → Advanced settings → Certificate
and network wake**. Enable network wake on the TV itself. Older authorizations may
need **Re-pair** to grant the new network-state read permission.

Power lives on the remote. When offline wake is configured by the integration,
its power button sends a wake request and retries the connection while the TV
starts. Connection status shows errors and offers retry/settings actions. See the
[device-management review](docs/contexts/flutter/device-management-review.md).

iOS SSDP requires Apple's multicast entitlement/provisioning approval on physical
devices. It is requested in the runner but cannot be granted through source code.
Manual IP connection remains independent. Never claim background connectivity
or wake works on every phone, network, or television.

Ordinary startup preferences no longer access Keychain. If you used an older
build, **Preferences → Import older saved TVs** can recover its saved profiles/settings
with an explicit protected-storage read. Pairing keys remain in secure storage.

Find TVs now searches each active IPv4 network address and isolates interface
failures. If it fails, the message distinguishes denied access, unavailable routes,
and timeouts. Restart after native-code updates; hot reload does not install the
new platform channel or entitlements.

## Architecture and injection

| Package | Responsibility |
| --- | --- |
| `remote_core` | Device identity/metadata, categories, typed capability contracts, provider registry and safe errors |
| `remote_network` | SDK WebSocket/TLS transport, SSDP parsing/discovery and WOL |
| `remote_lg_webos` | LG provider, SSAP registration/correlation/subscriptions, separate pointer connection and commands |
| `remote_ui` | Typed item definitions, catalog, grid geometry, styling and the shared editing shell |
| `universal_remote_app` | Flutter UI, injected controllers, protected storage, platform permissions and multicast integration |

Injection follows Kap Games: `AppBootstrap.initialize()` constructs services,
`AppDependencies` owns their lifetime, and constructors supply them to screens
and controllers. `ValueNotifier`/`ListenableBuilder` update the UI. **Riverpod is
removed**, as requested. Protocol code contains no Flutter imports.

The updated DEVCOM `route_definer` 4.0.0 is pinned to its verified web-free Git
revision. App routes live in `lib/routes/`; the package entrypoint is
`MaterialApp.router`. The original policy and later secure-storage/test exceptions
are documented in [docs/dependencies.md](docs/dependencies.md).

The current source organization follows Kap Games: app wiring, routes, presentation
by context, domain services/contracts, data adapters, and shared themes. Every
class, widget State, enum and test double has its own file. Views compose named
widgets; event orchestration lives in viewmodels. Read
[the structure guide](docs/contexts/flutter/project-structure.md) and
[readability rules](docs/contexts/architecture/readability-rules.md).

## Validation commands

From the root:

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed packages apps/universal_remote_app/lib apps/universal_remote_app/test test tool
dart run tool/check_structure.dart
dart analyze
dart run tool/audit_dependencies.dart
dart test test packages/remote_core/test packages/remote_network/test packages/remote_lg_webos/test
cd apps/universal_remote_app
flutter test --no-pub
flutter build apk --debug --target-platform android-arm64 --no-pub
flutter build ios --simulator --debug --no-pub
```

The TLS tests create and remove temporary self-signed certificates; no production
credential is hardcoded. The older SDK-only smoke runner remains available as
`dart run tool/smoke_test.dart`. CI performs formatting, analysis, dependency audit,
package/widget tests and an Android debug build; no releases are published.

## Documentation

- [Context and readability refactor](docs/refactor-report.md)
- [Architecture and lifecycle](docs/architecture.md)
- [Capability evidence](docs/capability-model.md)
- [Discovery, transport and protocol boundaries](docs/protocols.md)
- [LG commands, pairing and firmware limits](docs/lg-webos.md)
- [Security, certificates and platform permissions](docs/security.md)
- [Adding a provider](docs/adding-a-provider.md)
- [Hardware checklist](docs/hardware-checklist.md)
- [Roadmap](docs/roadmap.md)
- [Implementation and validation report](docs/implementation-report.md)

Native builds are compile checks, not evidence of physical TV or mobile behavior.
See the report for exact results, environmental failures, and remaining limits.
