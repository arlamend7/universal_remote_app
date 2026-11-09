# Architecture V2 validation

## Baseline at 02e7cd1

The clean checkout passed static analysis, structure and dependency checks,
68 Dart tests and 105 Flutter tests. LG and gated Roku owned their SSDP calls.
Android TV owned Dart mDNS and used an injected Android-TV-specific iOS channel.
Discovery was dispatched from ProviderRegistry. Manual IP did not use discovery.

Existing provider IDs are `lg.webos`, `android.tv` and `roku.ecp`.
SavedDeviceMapper read `saved-devices.v1` as provider configurations. Pairing
credentials were stored under `client-key.<profile-id>`, and `dashboards.v1`
used the same device ID. iOS declared `_androidtvremote2._tcp` and multicast
entitlements. Android acquired its native multicast lock in DiscoveryController.

The adapted call sites are Bootstrap provider registration, DiscoveryController,
DiscoveryViewModel and the discovery sheet, the three manufacturer providers,
the iOS platform channel, SavedDeviceRepository and its native storage
allowlists, SavedDevicesController, DeviceDetails and Devices view models,
ConnectionController and the dashboard key lookup. Core and widget tests inject V2 protocols and provider definitions.

## Implementation checkpoints

| Phase | Scope |
| --- | --- |
| 01 | Pure Dart observation, requirements, match, profile, logical device and typed definition contracts |
| 02 | Protocol registry and manager with parallel provider and service searches, streamed results and cooperative cancellation |
| 03 | Shared SSDP/Dart mDNS and service-driven iOS Bonjour |
| 04 | LG, Android TV and Roku identifiers, conservative resolver and unresolved observations |
| 05 | Definition-based factory and optional policies for built-in integrations |
| 06 | Fresh V2 storage, profile preference, reversible association and credential ownership |
| 07 | Stable active controller and bounded fallback to an independently authorized profile after a network connection failure |
| 08 | Existing screens consume V2 discovery and profiles without changing remote rendering |
| 09 | Automated discovery, V2 storage, authorization, cancellation and fallback tests |
| 10 | Removed built-in manufacturer scans, updated exports and documentation |

## Automated checks

The V2 checkout passed locked dependency resolution, formatting, structure,
static analysis and the dependency audit. All 70 Dart tests and 111 Flutter
tests passed. Android debug, macOS release, iOS simulator and unsigned iOS
release builds compiled.

The V2 test suite adds independent provider failures, streamed device updates, cancellation,
namespaced identity, Android TV service validation, Nearby Devices integration,
isolation from V1 and corrupt V2 handling, reversible association, and fallback exclusions.
Existing fixtures cover LG TLS and controls, Android TV pairing/pinning, gated Roku
recognition and ECP, manual setup, app lifecycle, transport cleanup and layouts.

Limits of this implementation:

- No installed integration provides verified cross-provider identity. Linking is
  explicit and reversible. Logical IDs are seeded from the first V2 profile.
- An existing usable session stays on its active profile. Fallback is a single
  attempt at connection time, on an eligible network failure only.
- V2 ignores old saved devices, dashboards and pairing credentials. Corrupt
  V2 data is reported and preserved for recovery.

## Hardware status

The unsigned compilation and simulator do not verify physical discovery.
Validate LG and Android TV separately on signed iOS hardware, on Android, and
on macOS where applicable. Use the same LAN, test automatic and manual setup,
revoke and grant Local Network permission on iOS, cancel a scan, and record
build, platform and protocol diagnostics. LG SSDP requires Apple-approved
multicast signing. Roku hardware validation and distribution authorization
remain separate and its release gate is retained.

| Platform | LG webOS | Android TV |
| --- | --- | --- |
| iOS on a signed iPhone build | Pending | Pending |
| Android on a physical phone | Pending | Pending |
| macOS on the same LAN as real TVs | Pending | Pending |
