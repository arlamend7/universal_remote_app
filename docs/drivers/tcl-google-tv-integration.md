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

TCL stays on `android.tv.remote-v2` with its unrestricted `bootstrap` profile.
No TCL profile is shipped, because no TCL behaviour that differs from other
Remote v2 televisions has been verified. Resolver tests
(`remote_driver_manager/test/selection/android_tv_compatibility_test.dart`)
prove that a reported vendor or model, or unknown OS and firmware, never
reject the integration or switch profile, and that a model profile *would*
apply once evidence exists.

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

## 5. Verification status

Result values: **Automated test passed**, **Hardware verified**,
**Unsupported**, **Not tested**. No TCL hardware has been available, so every
hardware column is *Not tested*.

| Feature | Expected behaviour | Actual (automated) | Result | Notes | Device/firmware tested |
|---|---|---|---|---|---|
| Discovery | `_androidtvremote2._tcp` on 6466 is identified | — | Not tested | | none |
| Pairing | 6-hex code, pinned certificate | — | Not tested | | none |
| Navigation | KeyEvent 19–23, 4, 3 | — | Not tested | | none |
| Volume | 24/25/164; feedback when bit 64 reported | — | Not tested | | none |
| Media | 126/127/86/89/90/88/87 | — | Not tested | | none |
| Text input | IME batch edit when bit 4 negotiated | — | Not tested | | none |
| Applications | App links when bit 512 negotiated | — | Not tested | | none |
| Power / wake | 223 off; Wake-on-LAN with learned MAC | — | Not tested | | none |
| Reconnection | Pinned credential reused | — | Not tested | | none |
