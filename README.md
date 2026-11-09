# Universal Remote

A local-first universal remote built with Flutter and reusable Dart packages.
It supports compatible LG webOS, Android TV / Google TV, and Samsung Tizen televisions.

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

## Connect a TCL Google TV

Turn on the TV and keep it on the same network as the app. Choose it under
**Find Nearby Devices**, or use **Connect by IP** and select **Google TV / Android TV**.
Enter the six characters shown on the TV when prompted. The app stores the
client identity in protected storage and checks the paired TV certificate on
reconnect.

Android TV support covers direction, OK, Back, Home, media keys, and relative
volume when remote key input is negotiated. A valid volume report enables the level display.
Power off is offered when the remote service advertises power and keys.
The Android TV provider has been tested with a local TLS server. Physical TCL
compatibility remains to be verified.

### Connect a Bluetooth soundbar

Put the soundbar in Bluetooth pairing mode and choose **Bluetooth & accessories**
from the remote menu. The shortcut is shown when the connected TV supports it.

- On Google TV, open **Remotes & Accessories → Pair remote or accessory** using the TV settings.
- On LG webOS, open **Sound Out → Use Wireless Speaker → Bluetooth Devices**.
  The names vary by webOS version.

Select the soundbar on the TV. Use the same TV menu to reconnect or disconnect
it. The accessory list and pairing confirmation appear on the TV screen.

If an LG TV exposes its paired audio devices to the network remote, the
editor also offers **Bluetooth devices** and **Bluetooth device shortcut**.
Use the first to choose a paired device, or pin one accessory with the second.
Tapping a device toggles its current connection. Initial pairing still uses
the TV menu.

## Connect by IP

Enter the TV's local IP address and leave **TV platform** set to
**Detect automatically**. Enabled providers check that address in parallel.
A single match continues to connection and pairing. If detection finds no
match or several matches, choose the TV platform manually. Some firmware
answers Nearby discovery while ignoring direct identification probes.

## Connect a Samsung Tizen TV

1. Turn the TV on and connect it and your phone or computer to the same local network.
2. Open **Find Nearby Devices**, or choose **Connect by IP → Samsung Tizen**.
3. Open **Review TV certificate and pair** on the remote screen and verify the fingerprint
   for your TV. Then choose **Allow** when the TV asks to pair.
4. For wake from standby, enable **Power On with Mobile** on the TV and set its
   active network interface's MAC address in **Device details** if it has not
   been learned automatically.

The provider uses the secure local remote channel on port 8002. It reuses an
issued pairing token, supports navigation, relative volume, channel steps, media
keys and power, and shows app shortcuts when the firmware reports an installed
app catalog. App listing, launch behavior and standby wake vary by firmware.
Automated tests use a simulated TV session. Physical Samsung TVs have not been
verified.

## Test Roku locally

Roku ECP is available in opt-in development builds for authorized local testing.
See [Roku feasibility and setup](docs/roku-feasibility.md) for the build flag,
device settings and supported controls.

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

### Verify discovery on iOS

The Runner Info.plist declares the Local Network usage description and
`_androidtvremote2._tcp`. Android TV uses Apple's Bonjour browser on iOS and
needs Local Network access. LG webOS sends SSDP multicast on Wi-Fi or Ethernet
and also needs Apple's multicast networking entitlement. The Runner Debug,
Profile, and Release configurations reference `Runner.entitlements`.
The source entitlement is a request. The Apple team must have approval and
the provisioning profile used for the export must authorize it.
See [Apple's local network privacy guidance](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy).

Before uploading to TestFlight, unpack the exported IPA and inspect the app
signature and, when present, its embedded provisioning profile:

```sh
app="/path/to/Payload/Runner.app"
codesign -d --entitlements :- "$app"
security cms -D -i "$app/embedded.mobileprovision" | plutil -extract Entitlements xml1 -o - -
```

For LG discovery, confirm `com.apple.developer.networking.multicast` is true
in both. If it is absent, check the App ID and team approval, regenerate the
profile, then re-export and verify the signature. A Dart socket errno alone
cannot distinguish a missing entitlement from Local Network denial or a
routing problem.

On a physical iPhone, connect to the same LAN as the TVs and test LG and
Android TV separately. Test with Local Network disabled, enable it for
Universal Remote in Settings, then tap **Search again**. Close the sheet
during a scan, reopen it, and check **Connect by IP** independently with
permission enabled. If discovery fails, open **Search details → Copy
diagnostics**. Record the build, provider, operation, OS error, and whether
manual IP works. The diagnostic report excludes TV addresses and pairing
credentials. Simulator runs and automated tests do not verify physical iOS
network permissions or TV compatibility.

Never claim background connectivity or wake works on every phone, network,
or television.

V2 uses a fresh device registry, dashboard store and pairing-key namespace.
Old device data is ignored and remains untouched. Add your TVs again to set up
V2 profiles. Pairing keys are stored separately from ordinary preferences.

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
dart test test packages/remote_core/test packages/remote_network/test packages/remote_lg_webos/test packages/remote_android_tv/test packages/remote_roku/test packages/remote_samsung_tizen/test
cd apps/universal_remote_app
flutter test --no-pub
flutter build apk --debug --target-platform android-arm64 --no-pub
flutter build ios --simulator --debug --no-pub
```

The TLS tests create and remove temporary self-signed certificates; no production
credential is hardcoded. CI performs formatting, analysis, dependency audit,
package/widget tests and an Android debug build; no releases are published.

## Documentation

- [Architecture and lifecycle](docs/architecture.md)
- [Capability evidence](docs/capability-model.md)
- [Discovery, transport and protocol boundaries](docs/protocols.md)
- [LG commands, pairing and firmware limits](docs/lg-webos.md)
- [Security, certificates and platform permissions](docs/security.md)
- [Adding a provider](docs/adding-a-provider.md)
- [Hardware checklist](docs/hardware-checklist.md)
- [Roadmap](docs/roadmap.md)

Native builds are compile checks, not evidence of physical TV or mobile behavior.

## Provider capabilities

See the [provider capability audit](docs/provider-capability-audit.md) for supported commands, test coverage, and firmware limits.
