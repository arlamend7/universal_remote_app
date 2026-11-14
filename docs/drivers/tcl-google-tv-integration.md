# TCL Google TV / Android TV integration

TCL televisions that run Google TV or Android TV use the existing
`android.tv.remote-v2` integration (`drivers/providers/android-tv/remote-v2/`),
the `android-remote-v2` engine and `GenericTvController`. There is no TCL
controller, provider, engine or driver folder. This document records the audit,
the protocol evidence, the changes made and the verification status.

## 1. Audit of the existing integration (2026-11-11)

### Discovery and identity

| Rule | Behaviour | Source |
|---|---|---|
| Service | Bonjour `_androidtvremote2._tcp`, advertised port must be `6466` | `drivers/providers/android-tv/remote-v2/discovery.json`, `declarative_identifier.dart` (`_accepts`) |
| Manufacturer filter | **None.** `manufacturer` is display data (`DiscoveryRules.manufacturer`, `ManualSetupRules.manufacturer`); nothing accepts or rejects a device by manufacturer | `discovery_rules.dart`, `manual_setup_rules.dart` |
| Records read | PTR → SRV → first IPv4 A. Metadata was only the instance name; TXT was never read | `remote_network/lib/src/bonjour/mdns_discovery.dart`, `ios_bonjour.dart` |
| Stable identity | TLS to 6467 without trust; base64 SHA-256 of the certificate DER (900 ms). ID `android-tv-<fingerprint>`, `stableIdentity: true`. If unreadable: `newProfileId()`, `stableIdentity: false` | `declarative_identifier.dart`, `discover_peer_identity.dart` |
| Deduplication | Equal peer fingerprints are the same device; otherwise same ID + shared endpoint + stable identity | `remote_core/lib/src/discovery/device_identifier_resolver.dart` |
| Manual IP | Numeric unicast address; recognized when 6466 and 6467 present the same certificate; random profile ID until the first connection stores `verifiedPeerIdentity` | `declarative_manual_setup.dart`, `provider_registry.dart` |
| Manufacturer/model | Always null: discovery.json declares neither, and the TV's own report was discarded | `legacy_devices.json` golden |

### Session

| Rule | Behaviour | Source |
|---|---|---|
| Pairing | TLS 6467, polo messages 10→11, 20→20, 30→31, 6-hex code (2 min), local checksum, 40→41. Non-200 → `pairing`. | `remote_v2/protocol/android_pairing.dart`, `pairing_proof.dart` |
| Credential | `PairedIdentity {certificate, key, peer}` under the device ID (`credentialScope: device`), never deleted automatically | `session_opener.dart`, `connection_controller.dart` |
| Pinning | 6466 fingerprint must equal the fingerprint pinned at pairing (`certificate` otherwise). No global trust bypass. | `android_remote_session.dart` |
| Configure | TV `{1:{1:features, 2:device info}}`; only the features were read; reply masks to `1\|2\|4\|32\|64\|512` | `android_remote_session.dart` |
| Facts | `feature.keys`, `feature.volume-keys` (= keys), `feature.power` (2 and 32), `feature.ime`, `feature.app-links`, `volume.reported`, `audio.absolute`, `audio.adjustable` | `remote_v2_engine_session.dart` |
| Software | `operatingSystem: "Android TV"` (connection.json), `protocolVersion: "Remote v2"`; everything else unknown | `remote_v2_engine_session.dart` |
| Reconnection | `connection.json` has no `session` block → 0 reconnect attempts; no `device.json` policy (no retry after wake, default merge) | `session_policy.dart`, `generic_tv_controller.dart` |

### Selection

`IntegrationResolver` filters candidates by `providerId`, bootstraps with the
highest-priority integration (a null model never excludes a candidate) and,
after identification, keeps candidates whose compatibility *matches*. Unknown
evidence never matches and never rejects an unrestricted integration.
Compatibility fields are `osVersion`, `firmwareVersion`, `models` and
`versionScheme`; **manufacturer is not a matching criterion**.

### Gaps found

1. Nothing rejects a TCL Google TV, but nothing identifies it either: TXT,
   discovery metadata and the TV's `RemoteDeviceInfo` were all ignored, so
   `models` profiles and `restrictions.model` could never match an Android TV.
2. `GenericTvController` copied the model from software information but not the
   manufacturer.
3. When the 6467 probe fails (slow TV, standby), each sighting gets a random ID
   and duplicate tiles never merge.
4. No automatic reconnection and no retry after Wake-on-LAN.
5. The 2-minute pairing-code wait surfaced as a raw `TimeoutException`; a wrong
   code rejected by the TV (status 402) was indistinguishable from a refusal.
6. Docs drift: `parity/android-tv.md` cited the removed `adapters/android_tv`
   sources and said the name came from TXT.

## 2. Protocol evidence

There is no official public specification of Android TV Remote v2. **D** =
stated by the source, **I** = inferred.

| Fact | Kind | Source |
|---|---|---|
| Service `_androidtvremote2._tcp`; TXT key `bt` required by Home Assistant and used as its unique ID | D | [HA config_flow](https://raw.githubusercontent.com/home-assistant/core/dev/homeassistant/components/androidtv_remote/config_flow.py) |
| `bt` is a Bluetooth MAC (v1 service) | D (v1) / I (v2) | [tinydnssd](https://github.com/youviewtv/tinydnssd) |
| Remote port 6466, pairing port 6467, both TLS, varint length-prefixed protobuf | D | [androidtvremote2](https://github.com/tronikos/androidtvremote2), [Aymkdn write-up](https://github.com/Aymkdn/assistant-freebox-cloud/wiki/Google-TV-(aka-Android-TV)-Remote-Control-(v2)) |
| Pairing status codes 200 OK, 400 ERROR, 401 BAD_CONFIGURATION, 402 BAD_SECRET | D | [polo.proto](https://raw.githubusercontent.com/tronikos/androidtvremote2/main/src/androidtvremote2/polo.proto) |
| `RemoteConfigure {code1=1 features, device_info=2}`; `RemoteDeviceInfo {model=1, vendor=2, unknown1=3, unknown2=4, package_name=5, app_version=6}` | D | [remotemessage.proto](https://raw.githubusercontent.com/tronikos/androidtvremote2/main/src/androidtvremote2/remotemessage.proto) |
| Feature bits PING 1, KEY 2, IME 4, VOICE 8, POWER 32, VOLUME 64, APP_LINK 512 | D | remotemessage.proto / remote.py |
| Absolute volume is not supported by the Remote Service | D (maintainer) | [home-assistant/core#176505](https://github.com/home-assistant/core/issues/176505) |
| Android KeyEvent values | D | [KeyEvent](https://developer.android.com/reference/android/view/KeyEvent) |
| Remote v2 does not expose the Android OS version, firmware or build | I | none of the messages above carries them |

## 3. TCL platforms

| TCL platform | Advertises | Integration |
|---|---|---|
| Google TV | `_androidtvremote2._tcp` (Android TV Remote Service) | `android.tv.remote-v2` |
| Android TV | Same, when the Remote Service is v2-capable. Old services only speak v1; an Android 9 TCL set failed pairing until the service was updated ([androidtvremote2#12](https://github.com/tronikos/androidtvremote2/issues/12)) | `android.tv.remote-v2` |
| Roku TV | SSDP `roku:ecp`, port 8060, `vendor-name` TCL ([Roku ECP](https://developer.roku.com/docs/developer-program/dev-tools/external-control-api.md)) | `roku.ecp.supported` (development channel: hidden in release builds) |
| Fire TV | No Remote Service | none |

A device is matched by the protocol it advertises, never by brand, so the
platforms cannot cross-match.

Documented TCL observations (not verified here):

- TCL sets can become unreachable when turned off unless *Screenless service*
  (Settings › System › Power and energy) or *Network Standby* (Settings ›
  Network & Internet; Google TV mode only) is enabled
  ([HA docs](https://www.home-assistant.io/integrations/androidtv_remote/),
  [home-assistant/core#107649](https://github.com/home-assistant/core/issues/107649)).
- On a TCL 65C805 the TV, MENU, INFO, GUIDE and CHANNEL± keys had no effect
  ([home-assistant/core#113736](https://github.com/home-assistant/core/issues/113736)).
  A key the TV ignores produces no error, so the app cannot detect it.
- Volume works as up/down/mute only (#176505).

## 4. Changes

### Identification (generic; no TCL string in code)

- **Device-reported identity.** The Remote v2 session decodes the TV's
  `RemoteDeviceInfo` (`AndroidDeviceInfo`: model, vendor, Remote Service package
  and version; untrusted text is stripped of control characters and bounded to
  100 characters). The engine reports `manufacturer` = vendor and `model` =
  model as authenticated-session evidence. The Remote Service package and
  version are kept in `raw` (`remoteServicePackage`, `remoteServiceVersion`)
  because they describe the service, not the TV software.
  `operatingSystemVersion`, `firmwareVersion`, `softwareVersion` and
  `buildNumber` stay unknown — Remote v2 does not report them, and nothing is
  inferred from the model name.
- **Manufacturer on the device.** `GenericTvController` fills a *missing*
  `RemoteDevice.manufacturer` from the session; a manufacturer already known
  (discovery rules, saved profile) is preserved. So a TCL Google TV shows the
  vendor it reports, and every Android TV keeps `providerId: android.tv`.
- **TXT records.** Dart mDNS (Android, macOS) and the iOS Bonjour bridge now pass
  DNS-SD TXT entries as observation metadata `txt.<key>` (`BonjourTextRecord`:
  at most 16 entries, keys `[a-z0-9_.-]{1,32}`, values ≤ 128 characters, control
  characters removed, never shadowing `name`).
- **Correlation, not identity.** Discovery rules can copy one observed value into
  metadata with `{observed:<key>}`. `android-tv/remote-v2/discovery.json` maps
  `txt.bt` to `correlationIdentity`. `DeviceIdentifierResolver` treats two
  sightings as the same TV only when they share that value **and** an endpoint,
  and never when their peer identities differ; a provisional (random-ID)
  sighting never replaces a stable one. `bt` is documented as a Bluetooth MAC,
  so it is never used as a Wake-on-LAN address. Device IDs keep the
  `android-tv-<fingerprint>` format, so saved devices, credentials and
  dashboards are unchanged.

### Compatibility profiles

The Android TV integration uses key 223 for standby by default. The
`smart-tv-pro` profile overrides `power-off` with key 26 when the
authenticated session reports the exact model `Smart TV Pro`. This
compatibility change still needs a hardware test on the reported TCL.
Key 26 is a toggle, so the app sends it once after power-off confirmation.

When hardware shows a model-specific difference, add an `identified` profile
to `drivers/providers/android-tv/remote-v2/manifest.json`. Match on the exact
model string the TV reports in `RemoteDeviceInfo`: `models` is matched against
`hardwareModel ?? model`. Use `disabledCapabilities` or `mappingOverrides` for
the difference.

```json
{"id": "<verified-model>", "stage": "identified",
 "compatibility": {"models": ["<exact reported model>"]},
 "disabledCapabilities": ["<capability shown not to work>"]}
```

Do not key a profile on the vendor. Do not infer an Android version from the
model name. Do not disable the TV, MENU, INFO, GUIDE or CHANNEL± keys for TCL
from the single 65C805 report: a key the TV ignores cannot be detected, and
other TCL models may support them.

### Pairing

TCL uses the same Remote v2 pairing flow and the same generic pairing UI.
Generic hardening:

| Situation | Before | Now |
|---|---|---|
| Code not entered within 2 minutes | raw `TimeoutException` | `RemoteException('pairingTimeout')` |
| TV rejects the secret (status 402 BAD_SECRET) | `pairing` | `RemoteException('pairingCode')`, "enter the code shown on the TV" |
| TV refuses a step (400/401) or closes the socket | `pairing` | `pairing` (unchanged) |
| TV stops answering a step (10 s) | raw `TimeoutException` | `RemoteException('timeout')` |
| TLS to 6466 fails (TV reset or forgot the client) | `certificate` | `certificate`, with a re-pair hint |

The new codes are deliberately not `network` or `timeout`, so a pairing
failure never triggers a profile fallback or a Wake-on-LAN retry.

These behaviours are unchanged:
- Trust on 6467 still comes from the on-screen code.
- The 6466 certificate must still match the pinned fingerprint.
- No TLS verification was relaxed.
- The credential is stored only after a successful exchange and is never
  deleted automatically.

`FramedSocket` now observes `SecureSocket.done`. A peer reset still surfaces
through reads and `flush`, but no longer escapes as an unhandled asynchronous
error.

Tests:
- `test/engines/remote_v2/android_pairing_lifecycle_test.dart` drives a
  scripted pairing TV through: success, local checksum, 402, 400/401,
  silent TV, code timeout, socket close, cancel and unreachable port.
- `remote_v2_engine_pairing_test.dart` checks the prompt and the credential at
  engine level.
- `android_remote_protocol_test.dart` covers the pinned reconnect and a
  mismatched pin.

### Capabilities

Capabilities come only from the Remote v2 features the TV negotiates and the
audio reports it sends; the vendor plays no part.
`test/engines/remote_v2/remote_v2_capability_evidence_test.dart` drives the
real `android-tv/remote-v2` integration through `GenericTvController` and
checks the following.

| Negotiated / reported | Exposed | Not exposed |
|---|---|---|
| KEY (2) | navigation, media, digits, settings, menu/info/guide, track, Live TV, captions, input picker, channels, volume keys | — |
| no KEY | — | every key-driven control and power |
| IME (4) | text input, current content | — |
| APP_LINK (512) | applications (safe app links only; no app list exists in Remote v2) | — |
| POWER (32) + KEY | power off | — |
| VOLUME (64) + audio mode 2 | volume feedback, exact volume, mute | — |
| VOLUME + audio mode 1 | volume feedback, mute | exact volume |
| no VOLUME | volume keys | feedback, exact volume (reports ignored) |

The same feature set gives the same controls and the same KeyEvent codes for
TCL, Google and Sony vendor strings. `feature.volume-keys` intentionally
equals KEY rather than VOLUME, because volume key injection does not depend on
bit 64. Gating it on bit 64 would remove volume keys from existing TVs.

Exact volume is still exposed only when the TV itself reports an absolute
audio output (mode 2). Upstream reports that the Remote Service does not
support setting an absolute level, and that TCL sets only honour up, down and
mute, so exact volume on TCL is **unverified**. Two further items are deferred
until hardware evidence exists:
- a `WAKEUP` (224) power-on alternative
- any TCL-specific key restriction

### Discovery and reconnection

These changes apply to every Remote v2 TV. They are needed most on TCL sets,
which tend to drop off the network in standby.

- **`connection.json#session.reconnectAttempts: 3`.** An unexpected session loss
  reconnects after 1 s, 2 s and 4 s with the stored pairing. A user disconnect
  never reconnects.
- **`device.json#policy`.**
  - `retryAfterWake` covers `network`, `networkAccess`, `connectionRefused`
    and `timeout`. Pairing and certificate errors never trigger a
    wake-and-retry.
  - `mergeDiscovered: replace-host` means a TV found at a new IP keeps its
    saved ID, name, metadata, credential and dashboard; only the host
    changes.
  - `sameConnection` adds `macAddress`, `broadcastAddress` and
    `verifiedPeerIdentity`, so a different pinned TV is never treated as
    the active connection.
- **Typed connection errors.** The Remote v2 engine maps socket and timeout
  failures through the shared `transportConnectionError` (as SSAP does), so
  a refused or unreachable TV reports `connectionRefused`, `networkAccess`,
  `network` or `timeout` instead of a raw `SocketException`. Protocol,
  pairing and certificate errors pass through unchanged. One app-level
  side effect: OS error 65 (`EHOSTUNREACH`) now reports `networkAccess`, which
  matches LG and is not a profile-fallback code.
- **Identity.** Stable IDs remain the certificate fingerprint and never the IP
  address. Duplicate advertisements and fingerprint-less sightings merge as
  described above; two TVs with different certificates stay separate; a
  manually added TV is recognized when discovered later through its pinned
  fingerprint.

Tests:
- `test/engines/remote_v2/remote_v2_reconnection_test.dart`: drop and
  reconnect without re-pairing; no reconnect after a user disconnect; refused
  remote and pairing ports are typed.
- `test/devices/android_tv_connection_policy_test.dart`
- `test/devices/android_tv_txt_identity_test.dart`

### Publication

TCL support ships as an update of the existing `android.tv.remote-v2` package:
no new integration, folder or numbered release. The only package change is in
`discovery.json` (TXT correlation), `connection.json` (reconnection) and
`device.json` (policy). The publisher stamps `lastUpdatedAt`, produces a new
SHA-256 object and signs the package and catalog. Installed apps pick it up
through the normal hash-based update, and the bundled seed is refreshed from
the verified live catalog. The engine changes (device info, typed errors,
pairing) ship with the app build, so older app builds keep working with the
new package.

## 5. Verification status

Result values: **Automated test passed**, **Hardware verified**,
**Unsupported**, **Not tested**. Automated results come from loopback fakes
built from documented protocol shapes, not from TCL captures. No TCL TV has
been available, so every hardware result is *Not tested*.

| Feature | Expected behaviour | Automated | Hardware | Notes | Device/firmware tested |
|---|---|---|---|---|---|
| Discovery | `_androidtvremote2._tcp` on 6466; ID from the 6467 certificate; TXT `bt` correlates | Automated test passed | Not tested | `android_tv_txt_identity_test`, `bonjour_text_record_test`, iOS bridge test | none |
| Identification | Vendor/model from `RemoteDeviceInfo`; OS/firmware unknown | Automated test passed | Not tested | Exact TCL vendor/model strings unknown | none |
| Platform separation | Roku TV → `roku.ecp`; other services never match | Automated test passed | Not tested | Roku is development-only | none |
| Pairing | 6-hex code, pinned certificate, typed failures | Automated test passed | Not tested | `android_pairing_lifecycle_test`, `remote_v2_engine_pairing_test` | none |
| Certificate pinning | 6466 must match the pinned 6467 certificate | Automated test passed | Not tested | Same-certificate assumption unverified on TCL | none |
| Navigation | KeyEvent 19–23, 4, 3 | Automated test passed | Not tested | | none |
| Volume | 24/25/164; feedback when VOLUME + report | Automated test passed | Not tested | TCL reported as up/down/mute only | none |
| Exact volume | Only for an absolute output report | Automated test passed | Not tested | Upstream says unsupported by the service | none |
| Media | 126/127/86/89/90/88/87 | Automated test passed | Not tested | | none |
| Special keys | Settings 176, menu 82, info 165, guide 172, Live TV 170, captions 175, input 178, CH± 166/167, digits | Automated test passed | Not tested | One TCL model ignored TV/MENU/INFO/GUIDE/CH± | none |
| Text input | IME batch edit when IME negotiated | Automated test passed | Not tested | | none |
| Applications | App links when APP_LINK negotiated | Automated test passed | Not tested | No app list in Remote v2 | none |
| Power off | With POWER + KEY, send 223 by default or 26 for the Smart TV Pro profile | Mapping and profile selection covered | Not tested | Verify the reported model and screen behavior | none |
| Wake | Open the advertised Bonjour wake port, then send key 224 over the paired session. Smart TV Pro defaults to port 6465 when no port was saved. Other devices can use Wake-on-LAN when a MAC is known. | Loopback coverage | Not tested | Verify the screen wakes on the reported TCL | none |
| Reconnection | Reconnect with the stored pairing; IP change keeps identity | Automated test passed | Not tested | | none |
| Persistence | Manufacturer, model, evidence saved; old devices load | Automated test passed | Not tested | | none |
